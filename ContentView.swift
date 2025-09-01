import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct MenuItemFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: TreeItemResult, Identifiable {
        public var childrens: [MenuItemFeature.State] = []
        var identifiedArrayOfChildrens: IdentifiedArrayOf<MenuItemFeature.State> = []

        public let id: String
        public var depth: Int = 0
        public let parentId: String?
        let title: String
        var isExpanded: Bool = false
        var isSelected: Bool = false

        var isPossibleToExpand: Bool {
            childrens.isEmpty == false
        }
    }

    public indirect enum Action {
        case onAppear
        case delegate(Delegate)
        case didTapItem(id: String)
        case childrens(IdentifiedActionOf<MenuItemFeature>)
    }

    @Dependency(\.menuItemFeatureClient.log) private var log

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: state.childrens)
                return .none
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
        .forEach(\.identifiedArrayOfChildrens, action: \.childrens) {
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

@Reducer
public struct MenuFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        var items: IdentifiedArrayOf<MenuItemFeature.State> = []

        public init() {}
    }

    public enum Action {
        case delegate(Delegate)
        case onFirstAppear
        case didLoadMenu([MenuItemFeature.State])
        case dismiss
        case items(IdentifiedActionOf<MenuItemFeature>)
    }

    @Dependency(\.menuFeatureClient.log) private var log
    @Dependency(\.menuFeatureClient.loadMenuItems) private var loadMenuItems

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onFirstAppear:
                log(.debug, "menu did appear for first time")
                return loadMenu()
            case let .didLoadMenu(items):
                log(.debug, "did load menu")
                state.items = IdentifiedArrayOf(uniqueElements: items)
                return .none
            case .delegate:
                return .none
            case .dismiss:
                return .none
            case .items(.element(id: _, action: .delegate(.didTapItem(let id)))):
                deselectAllItems(beside: id, in: &state.items)
                return .none
            case .items:
                return .none
            }
        }
        .forEach(\.items, action: \.items) {
            MenuItemFeature()
        }
    }

    private func deselectAllItems(
        beside id: String,
        in items: inout IdentifiedArrayOf<MenuItemFeature.State>
    ) {
        for index in items.indices {
            items[index].isSelected = items[index].id == id
            deselectAllItems(beside: id, in: &items[index].identifiedArrayOfChildrens)
        }
    }
}

extension MenuFeature {
    public enum Delegate: Sendable, Equatable {}
}

private extension MenuFeature {
    private func loadMenu() -> Effect<Action> {
        return .run { send in
            let groups = try? await loadMenuItems()
            await send(.didLoadMenu(groups ?? []))
        }
    }
}





private func collapseAllExcept(
    id: String,
    in items: inout IdentifiedArrayOf<MenuItemFeature.State>
) {
    for index in items.indices {
        if items[index].id == id {
            // keep it as is, but recurse into children
            collapseAllExcept(id: id, in: &items[index].identifiedArrayOfChildrens)
        } else {
            // collapse everything else
            items[index].isExpanded = false
            collapseAllExcept(id: id, in: &items[index].identifiedArrayOfChildrens)
        }
    }
}
