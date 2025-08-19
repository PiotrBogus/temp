import Foundation
import ComposableArchitecture

@Reducer
public struct MenuItemFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: TreeItemResult {
        var childrens: [any TreeItemResult]
        var castedChildrens: IdentifiedArrayOf<Self> {
            let bb = childrens as? [MenuItemFeature.State] ?? []
        }

        public let id: String
        let title: String
        let parentId: String?
        var isExpanded: Bool = false
        var isSelected: Bool = false

        var isPossibleToExpand: Bool {
            childrens.isEmpty == false
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.parentId == rhs.parentId &&
            lhs.childrens.count == rhs.childrens.count
        }
    }

    public indirect enum Action {
        case delegate(Delegate)
        case didTapItem(id: String)
        case childrens(IdentifiedActionOf<MenuItemFeature>)
    }

    @Dependency(\.menuItemFeatureClient.log) private var log

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .didTapItem(id):
                log(.debug, "did tap item: \(id)")
                if state.isPossibleToExpand {
                    state.isExpanded = !state.isExpanded
                    return .none
                } else {
                    state.isSelected = !state.isSelected
                    return .send(.delegate(.didTapItem(id: id)))
                }
            case .childrens(.element(id: _, action: .delegate(.didTapItem(let id)))):
                return .send(.delegate(.didTapItem(id: id)))
            case .childrens:
                return .none
            case .delegate:
                return .none
            }
        }
        .forEach(\.childrens, action: \.childrens) {
            MenuItemFeature()
        }
    }
}

extension MenuItemFeature {
    public enum Delegate: Sendable, Equatable {
        case didTapItem(id: String)
    }
}


import Foundation
import ComposableArchitecture

protocol TreeItemResult: Identifiable, Equatable {
    var id: String { get }
    var parentId: String? { get }
    var childrens: [any TreeItemResult] { get set }
}

