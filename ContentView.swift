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
                state.items = collapseAndDisableAllItems(items: state.allItems, isDisabled: !isOn)
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
        items: IdentifiedArrayOf<AlternativeItemFeature.State>,
        isDisabled: Bool
    ) -> IdentifiedArrayOf<AlternativeItemFeature.State> {

        let updatedItems = items.map { item in
            var updatedItem = item
            updatedItem.isExpanded = false
            updatedItem.isDisabled = isDisabled

            updatedItem.identifiedArrayOfChildrens = collapseAndDisableAllItems(
                items: item.identifiedArrayOfChildrens,
                isDisabled: isDisabled
            )

            updatedItem.children = updatedItem.identifiedArrayOfChildrens

            return updatedItem
        }

        return IdentifiedArrayOf(uniqueElements: updatedItems)
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
