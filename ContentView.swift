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

        public enum Delegate: Sendable, Equatable {
            case dismiss
            case didSelectItem(Int)
        }
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
}
