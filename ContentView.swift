import Foundation
import ComposableArchitecture
import AppCompositionDomain

@Reducer
public struct MenuItemFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: TreeItemResult, Identifiable, Sendable {
        public var children: [MenuItemFeature.State] = []
        var identifiedArrayOfChildrens: IdentifiedArrayOf<MenuItemFeature.State> = []

        public let id: String
        public let parentId: String?
        let title: String
        var isExpanded: Bool = false
        var isSelected: Bool = false

        var isPossibleToExpand: Bool {
            children.isEmpty == false
        }
    }

    public indirect enum Action: Sendable {
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
                    state.isExpanded = !state.isExpanded
                } else {
                    state.isSelected = !state.isSelected
                }
                return .send(.delegate(.didTapItem(.init(id: id, isExpand: state.isPossibleToExpand))))
            case let .children(.element(id: _, action: .delegate(.didTapItem(id, isExpand)))):
                return .send(.delegate(.didTapItem(.init(id: id, isExpand: isExpand))))
            case .children:
                return .none
            case .delegate:
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
