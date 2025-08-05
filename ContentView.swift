    private static func groupItemsIntoTree(_ flatItems: [MenuItemApiMock]) -> [MenuItemFeature.State] {
        var lookup: [String: MenuItemFeature.State] = [:]
        var roots: [MenuItemFeature.State] = []

        for item in flatItems {
            lookup[item.id] = MenuItemFeature.State(id: item.id, title: item.title, parentId: item.parentId, childrens: [])
        }

        for item in flatItems {
            guard let node = lookup[item.id] else { continue }

            if let parentId = item.parentId,
                var parent = lookup[parentId] {
                parent.childrens.append(node)
                lookup[parentId] = parent
            } else {
                roots.append(node)
            }
        }

        func attachChildren(for node: MenuItemFeature.State) -> MenuItemFeature.State {
            var updatedNode = node
            updatedNode.childrens = IdentifiedArrayOf(uniqueElements: node.childrens.map { attachChildren(for: lookup[$0.id] ?? $0) })
            return updatedNode
        }

        return roots.map { attachChildren(for: $0) }
    }

import Foundation
import ComposableArchitecture

@Reducer
public struct MenuItemFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Identifiable {
        public let id: String
        let title: String
        let parentId: String?
        var childrens: IdentifiedArrayOf<MenuItemFeature.State>
        var isExpanded: Bool = false
        var isSelected: Bool = false

        var isPossibleToExpand: Bool {
            childrens.isEmpty == false
        }

        mutating func attachChildrens(newValue: IdentifiedArrayOf<MenuItemFeature.State>) {
            childrens = newValue
        }
    }

    public indirect enum Action {
        case didTapItem(id: String)
        case childrens(IdentifiedActionOf<MenuItemFeature>)
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .didTapItem(id):
//                log(.debug, "did tap item: \(id)")
                if state.isPossibleToExpand {
                    state.isExpanded = !state.isExpanded
                }
                return .none
            case .childrens:
                return .none
            }
        }
    }
}

extension MenuItemFeature {
    public enum Delegate: Sendable, Equatable {}
}
