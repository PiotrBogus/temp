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
        var isOn: Bool = true
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
        case toggleChanged(Bool)

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
                guard text != state.searchText else {
                    return .none
                }
                
                state.searchText = text
                guard !text.isEmpty else {
                    return .send(.didFilter(state.allItems))
                }

                return performFilter(with: text, allItems: state.allItems)
                    .debounce(
                        id: CancelID.filter,
                        for: .milliseconds(300),
                        scheduler: RunLoop.main
                    )

            case let .didFilter(items):
                state.items = items
                return .none


            case let .toggleChanged(isOn):
                state.isOn = isOn
                state.searchText = ""
                state.items = state.allItems
                if !isOn {
                    collapseAndDisableAllItems(items: &state.items, isDisabled: !isOn)
                }

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

    private func collapseAndDisableAllItems(
        items: inout IdentifiedArrayOf<AlternativeItemFeature.State>,
        isDisabled: Bool
    ) {
        for index in items.indices {
            items[index].isDisabled = isDisabled
            items[index].isExpanded = false
        }
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
            let filteredItems = await Task.detached(priority: .userInitiated) {
                let filteredItems = filterTree(
                    items: allItems,
                    searchText: text.lowercased()
                )
                return filteredItems
            }.value

            await send(.didFilter(filteredItems))
        }
    }

    private func filterTree(
        items: IdentifiedArrayOf<AlternativeItemFeature.State>,
        searchText: String
    ) -> IdentifiedArrayOf<AlternativeItemFeature.State> {

        var results: [AlternativeItemFeature.State] = []

        func collectMatching(_ item: AlternativeItemFeature.State) {
            let titleMatches = item.title.lowercased().contains(searchText)

            if titleMatches {
                var matchedItem = item
                matchedItem.children = item.children
                matchedItem.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: item.children)
                matchedItem.isExpanded = true
                results.append(matchedItem)
            } else {
                for child in item.children {
                    collectMatching(child)
                }
            }
        }

        for item in items {
            collectMatching(item)
        }

        return IdentifiedArrayOf(uniqueElements: results)
    }
}



import Foundation
import ComposableArchitecture
import GenieCommonDomain

@Reducer
public struct AlternativeItemFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: TreeItemResult, Identifiable, Sendable, Equatable {
        public var children: [AlternativeItemFeature.State] = []
        var identifiedArrayOfChildrens: IdentifiedArrayOf<AlternativeItemFeature.State> = []

        public let id: Int
        public let parentId: Int?
        public let level: Int
        let title: String
        public var isExpanded: Bool = false
        public var isSelected: Bool = false
        public var isDisabled: Bool = false

        var isPossibleToExpand: Bool {
            !children.isEmpty
        }
    }

    public indirect enum Action: Sendable, Equatable {
        case onAppear
        case delegate(Delegate)
        case didTapItem(id: Int)
        case didExpandItem(id: Int)
        case children(IdentifiedActionOf<AlternativeItemFeature>)
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: state.children)
                return .none

            case let .didTapItem(id):
                guard !state.isDisabled else { return .none }
                state.isSelected.toggle()
                let tapItem = AlternativeViewItemTapModel(id: id, isExpand: false)
                return .send(.delegate(.didTapItem(tapItem)))

            case let .didExpandItem(id):
                guard !state.isDisabled, state.isPossibleToExpand else { return .none }
                state.isExpanded.toggle()
                let tapItem = AlternativeViewItemTapModel(id: id, isExpand: true)
                return .send(.delegate(.didTapItem(tapItem)))

            case let .children(.element(_, .delegate(.didTapItem(model)))):
                return .send(.delegate(.didTapItem(model)))

            case .children, .delegate:
                return .none
            }
        }
        .forEach(\.identifiedArrayOfChildrens, action: \.children) {
            AlternativeItemFeature()
        }
    }
}

extension AlternativeItemFeature.Action {
    @CasePathable
    public enum Delegate: Sendable, Equatable {
        case didTapItem(AlternativeViewItemTapModel)
    }
}

public struct AlternativeViewItemTapModel: Sendable, Equatable {
    public let id: Int
    public let isExpand: Bool
}



import SwiftUI
import ComposableArchitecture

struct AlternativeItemView: View {
    @Bindable var store: StoreOf<AlternativeItemFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                IndentationView(
                    level: store.level,
                    isExpandable: store.isPossibleToExpand,
                    isExpanded: store.isExpanded,
                    isSelected: store.isSelected
                )
                .onTapGesture {
                    store.send(.didExpandItem(id: store.id))
                }

                VStack {
                    Spacer()
                    HStack(spacing: .zero) {
                        Text(store.title)
                            .font(.body)
                            .fontWeight(store.isSelected ? .bold : .regular)
                        Spacer()
                    }
                    Spacer()
                }
                .overlay(
                    Rectangle()
                        .fill(Color.separator)
                        .frame(height: 1),
                    alignment: .bottom
                )
                .onTapGesture {
                    store.send(.didTapItem(id: store.id))
                }
            }
            .contentShape(Rectangle())

            if store.isExpanded {
                ForEachStore(
                    store.scope(
                        state: \.identifiedArrayOfChildrens,
                        action: \.children
                    )
                ) { childStore in
                    AlternativeItemView(store: childStore)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}


private struct IndentationView: View {
    let level: Int
    let isExpandable: Bool
    let isExpanded: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: .zero) {
            Rectangle()
                .fill(level > 0 ? Color.separator : Color.clear)
                .frame(width: 1, height: 14)
                .padding(.bottom, 2)

            if isExpandable {
                Image(systemName: isExpanded ? "minus.circle" : "plus.circle")
                    .foregroundColor(prepareColor(for: level))
                    .frame(width: 20, height: 20)
            } else {
                VStack {
                    Circle()
                        .fill(prepareColor(for: level))
                        .frame(width: 14, height: 14)
                }
                .frame(width: 20, height: 20)
            }
            Rectangle()
                .fill(level > 0 || (level == 0 && isExpanded) ? Color.separator : Color.clear)
                .frame(width: 1, height: 14)
                .padding(.top, 2)
        }
    }

    private func prepareColor(for level: Int) -> Color {
        switch level {
        case 0:
            Color(uiColor: .bluePrimary)
        case 1:
            Color(hex: 0x8d1f1b)
        case 2:
            Color(hex: 0xe74a21)
        case 3:
            Color(hex: 0xFCB13B)
        case 4:
            Color(hex: 0x6ad545)
        case 5:
            Color(hex: 0x45d5b1)
        default:
            Color.random()
        }
    }
}
