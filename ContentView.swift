import GenieCommonDomain
import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
public struct AlternativeViewFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        @Presents var error: ErrorFeature.State?

        var searchText: String = ""
        var isLoading: Bool = false
        var items: IdentifiedArrayOf<AlternativeItemFeature.State> = []
        var allItems: IdentifiedArrayOf<AlternativeItemFeature.State> = []
    }

    public enum Action: Sendable, Equatable {
        case delegate(Delegate)
        case onFirstAppear
        case dismiss
        case items(IdentifiedActionOf<AlternativeItemFeature>)
        case didLoadItems([AlternativeItemFeature.State])
        case onError(ErrorFeature.State)
        case error(ErrorFeature.Action)
        case searchTextChanged(String)
        case didFilter(IdentifiedArrayOf<AlternativeItemFeature.State>)

        public enum Delegate: Sendable, Equatable {
            case dismiss
            case didSelectItem(Int)
        }
    }

    enum CancelID {
        case filter
    }

    @Dependency(\.alternativeViewFeatureClient) private var featureClient

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none

            case .dismiss:
                return .send(.delegate(.dismiss))

            case let .items(.element(id: _, action: .delegate(.didTapItem(tapModel)))):
                if tapModel.isExpand {
                    keepAncestorsAndCollapseOthers(expandedId: tapModel.id, in: &state.items)
                    return .none
                } else {
                    deselectAllItems(beside: tapModel.id, in: &state.items)
                    return .send(.delegate(.didSelectItem(tapModel.id)))
                }

            case .items:
                return .none

            case .onFirstAppear:
                state.isLoading = true
                return loadData()

            case .didLoadItems(let newItems):
                state.isLoading = false
                state.allItems = IdentifiedArrayOf(uniqueElements: newItems)
                state.items = IdentifiedArrayOf(uniqueElements: newItems)
                return .none

            case let .onError(error):
                state.isLoading = false
                state.error = error
                return .none

            case .error(.delegate(.retry)):
                state.error = nil
                state.isLoading = true
                return loadData()

            case .error:
                return .none

            case let .searchTextChanged(text):
                state.searchText = text
                return performFilter(with: text, allItems: state.allItems)
                    .debounce(
                        id: CancelID.filter,
                        for: .milliseconds(300),
                        scheduler: RunLoop.main
                    )

            case let .didFilter(items):
                state.items = items
                return .none
            }
        }
        .forEach(\.items, action: \.items) {
            AlternativeItemFeature()
        }
    }

    private func deselectAllItems(
        beside id: Int,
        in items: inout IdentifiedArrayOf<AlternativeItemFeature.State>
    ) {
        for index in items.indices {
            items[index].isSelected = items[index].id == id
            deselectAllItems(beside: id, in: &items[index].identifiedArrayOfChildrens)
        }
    }

    @discardableResult
    private func keepAncestorsAndCollapseOthers(
        expandedId: Int,
        in items: inout IdentifiedArrayOf<AlternativeItemFeature.State>
    ) -> Bool {
        var found = false
        for index in items.indices {
            if items[index].id == expandedId {
                found = true
                keepAncestorsAndCollapseOthers(
                    expandedId: expandedId,
                    in: &items[index].identifiedArrayOfChildrens
                )
            } else {
                let childHasExpanded = keepAncestorsAndCollapseOthers(
                    expandedId: expandedId,
                    in: &items[index].identifiedArrayOfChildrens
                )

                if childHasExpanded {
                    items[index].isExpanded = true
                    found = true
                } else {
                    items[index].isExpanded = false
                }
            }
        }

        return found
    }

    private func loadData() -> Effect<Action> {
        return .run { send in
            do {
                let alternativeViewEntity = try await featureClient.fetchAlternativeViewEntity()
                let tree = featureClient.buildTree(alternativeViewEntity.items, alternativeViewEntity.defaultValueId)
                await send(.didLoadItems(tree))
            } catch {
                await send(.onError(.build(from: error)))
            }
        }
    }

    private func performFilter(
        with text: String,
        allItems: IdentifiedArrayOf<AlternativeItemFeature.State>
    ) -> Effect<Action> {
        return .run { send in
            if text.isEmpty {
                await send(.didFilter(allItems))
            } else {
                let filteredItems = filterTree(
                    items: allItems,
                    searchText: text.lowercased()
                )
                await send(.didFilter(filteredItems))
            }
        }
    }

    private func filterTree(
        items: IdentifiedArrayOf<AlternativeItemFeature.State>,
        searchText: String
    ) -> IdentifiedArrayOf<AlternativeItemFeature.State> {

        let filtered = items.compactMap { item in
            filterItem(item, searchText: searchText)
        }

        return IdentifiedArrayOf(uniqueElements: filtered)
    }


    private func filterItem(
        _ item: AlternativeItemFeature.State,
        searchText: String
    ) -> AlternativeItemFeature.State? {

        let titleMatches = item.title.lowercased().contains(searchText)

        let filteredChildren = item.children.compactMap {
            filterItem($0, searchText: searchText)
        }

        if titleMatches {
            var newItem = item
            newItem.children = item.children
            newItem.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: item.children)
            newItem.isExpanded = true
            return newItem
        }

        if !filteredChildren.isEmpty {
            var newItem = item
            newItem.children = filteredChildren
            newItem.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: filteredChildren)
            newItem.isExpanded = true
            return newItem
        }

        return nil
    }
}



import ComposableArchitecture
import GenieCommonDomain
import SwiftUI

public struct AlternativeView: View {

    @Bindable var store: StoreOf<AlternativeViewFeature>

    public init(store: StoreOf<AlternativeViewFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            if store.isLoading {
                loader
            } else {
                contentView
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
        .alert($store.scope(state: \.error?.alert, action: \.error.alert))
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEachStore(
                        store.scope(
                            state: \.items,
                            action: \.items
                        )
                    ) { itemStore in
                        AlternativeItemView(store: itemStore)
                    }
                }
            }
            .padding(.horizontal, 16)

            Divider()
            searchBar
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
    }

    @ViewBuilder
    private var loader: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
            .frame(height: 44)
    }
}

