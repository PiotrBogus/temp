import Foundation
import ComposableArchitecture
import AppCompositionDomain

@Reducer
public struct MenuItemFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: TreeItemResult, Identifiable, Sendable, Equatable {
        public var children: [MenuItemFeature.State] = []
        var identifiedArrayOfChildrens: IdentifiedArrayOf<MenuItemFeature.State> = []

        public let id: String
        public let parentId: String?
        let title: String
        var isExpanded: Bool = false
        var isSelected: Bool = false

        var isPossibleToExpand: Bool {
            !children.isEmpty
        }
    }

    public enum Action: Sendable, Equatable {
        case onAppear
        case delegate(Delegate)
        case didTapItem(id: String)
        case children(IdentifiedActionOf<MenuItemFeature>)
    }

    @Dependency(\.menuItemFeatureClient.log) private var log

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: state.children)
                return .none

            case let .didTapItem(id):
                log(.debug, "did tap item: \(id)")

                if state.isPossibleToExpand {
                    state.isExpanded.toggle()
                } else {
                    state.isSelected.toggle()
                }

                return .send(.delegate(.didTapItem(MenuItemTapModel(id: id, isExpand: state.isPossibleToExpand))))

            case let .children(.element(_, .delegate(.didTapItem(model)))):
                return .send(.delegate(.didTapItem(model)))

            case .children, .delegate:
                return .none
            }
        }
        .forEach(\.identifiedArrayOfChildrens, action: \.children) {
            MenuItemFeature()
        }
    }
}

extension MenuItemFeature {
    @CasePathable
    public enum Delegate: Sendable, Equatable {
        case didTapItem(MenuItemTapModel)
    }
}

public struct MenuItemTapModel: Sendable, Equatable {
    public let id: String
    public let isExpand: Bool
}
