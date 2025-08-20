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
                return .none
            case .items:
                return .none
            }
        }
        .forEach(\.items, action: \.items) {
            MenuItemFeature()
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




import Foundation
import ComposableArchitecture
import Data

@Reducer
public struct MenuItemFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: TreeItemResult {
        public var childrens: IdentifiedArrayOf<MenuItemFeature.State> = []

        public let id: String
        let title: String
        public let parentId: String?
        var isExpanded: Bool = false
        var isSelected: Bool = false

        var isPossibleToExpand: Bool {
            childrens.isEmpty == false
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






private func selectOnly(_ id: String, in items: inout IdentifiedArrayOf<MenuItemFeature.State>) {
    for index in items.indices {
        items[index].isSelected = (items[index].id == id)
        // rekurencja dla children
        selectOnly(id, in: &items[index].childrens)
    }
}
