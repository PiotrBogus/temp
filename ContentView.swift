import ComposableArchitecture
import SwiftUI

public struct AlternativeView: View {

    @Bindable var store: StoreOf<AlternativeViewFeature>

    public init(store: StoreOf<AlternativeViewFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchBar

            if store.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(height: 44)
            } else {
                listView
            }
        }
        .navigationTitle("Watchlist Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    store.send(.delegate(.dismiss))
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
        .onAppear {
            store.send(.onFirstAppear)
        }
    }

    @ViewBuilder
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.secondary)

            TextField(
                "Search items...",
                text: $store.searchText.sending(\.searchTextChanged)
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var listView: some View {
        List {
            ForEachStore(
                store.scope(
                    state: { $0.items.filter { $0.isVisible(in: store.visibleIDs) } },
                    action: \.items
                )
            ) { itemStore in
                AlternativeItemView(store: itemStore)
            }
        }
        .listStyle(PlainListStyle())
        .keyboardDismissMode(.interactive)
    }
}

// MARK: - Helper on AlternativeItemFeature.State
extension AlternativeItemFeature.State {
    func isVisible(in visibleIDs: Set<Int>) -> Bool {
        visibleIDs.contains(self.id)
    }
}


import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
public struct AlternativeViewFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        var searchText: String = ""
        var isLoading: Bool = false
        var allItems: IdentifiedArrayOf<AlternativeItemFeature.State> = []
        var items: IdentifiedArrayOf<AlternativeItemFeature.State> = []

        // IDs widocznych elementów po filtrze
        var visibleIDs: Set<Int> = []

        // Flat index + parent map do szybkiego search
        var flatIndex: [Int: AlternativeItemFeature.State] = [:]
        var parentMap: [Int: Int?] = [:]
    }

    public enum Action: Sendable, Equatable {
        case delegate(Delegate)
        case onFirstAppear
        case dismiss
        case items(IdentifiedActionOf<AlternativeItemFeature>)
        case didLoadItems([AlternativeItemFeature.State])
        case searchTextChanged(String)
        case didUpdateVisibleIDs(Set<Int>)

        public enum Delegate: Sendable, Equatable {
            case dismiss
            case didSelectItem(Int)
        }
    }

    enum CancelID { case filter }

    @Dependency(\.alternativeViewFeatureClient) private var featureClient

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .delegate:
                return .none

            case .dismiss:
                return .send(.delegate(.dismiss))

            case .onFirstAppear:
                state.isLoading = true
                return loadData()

            case let .didLoadItems(newItems):
                state.isLoading = false
                state.allItems = IdentifiedArrayOf(uniqueElements: newItems)
                state.items = IdentifiedArrayOf(uniqueElements: newItems)
                // budujemy flat index raz
                buildFlatIndex(for: &state)
                state.visibleIDs = Set(state.flatIndex.keys)
                return .none

            case let .searchTextChanged(text):
                state.searchText = text

                return .run { [flat = state.flatIndex, parents = state.parentMap] send in
                    let searchText = text.lowercased()
                    let ids = await Task.detached(priority: .userInitiated) {
                        searchIDs(searchText: searchText, flatIndex: flat, parentMap: parents)
                    }.value
                    await send(.didUpdateVisibleIDs(ids))
                }
                .debounce(id: CancelID.filter, for: .milliseconds(300), scheduler: RunLoop.main)

            case let .didUpdateVisibleIDs(ids):
                state.visibleIDs = ids
                return .none

            case .items:
                return .none
            }
        }
        .forEach(\.items, action: \.items) {
            AlternativeItemFeature()
        }
    }

    // MARK: - Helpers

    private func buildFlatIndex(for state: inout State) {
        state.flatIndex = [:]
        state.parentMap = [:]

        func traverse(item: AlternativeItemFeature.State, parent: Int?) {
            state.flatIndex[item.id] = item
            state.parentMap[item.id] = parent
            for child in item.children {
                traverse(item: child, parent: item.id)
            }
        }

        for item in state.allItems {
            traverse(item: item, parent: nil)
        }
    }

    private func searchIDs(
        searchText: String,
        flatIndex: [Int: AlternativeItemFeature.State],
        parentMap: [Int: Int?]
    ) -> Set<Int> {
        guard !searchText.isEmpty else {
            return Set(flatIndex.keys)
        }

        var result: Set<Int> = []

        for (id, item) in flatIndex {
            if item.title.lowercased().contains(searchText) {
                var current: Int? = id
                while let c = current {
                    result.insert(c)
                    current = parentMap[c] ?? nil
                }
            }
        }

        return result
    }

    private func loadData() -> Effect<Action> {
        .run { send in
            do {
                let entity = try await featureClient.fetchAlternativeViewEntity()
                let tree = featureClient.buildTree(entity.items, entity.defaultValueId)
                await send(.didLoadItems(tree))
            } catch {
                // handle error if needed
            }
        }
    }
}

