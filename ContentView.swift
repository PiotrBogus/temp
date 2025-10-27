import AppCompositionDomain
import ComposableArchitecture
import SwiftUI

@Reducer
public struct NotificationsFeature : Sendable{
    @ObservableState
    public struct State: Equatable, Sendable {
        var items: IdentifiedArrayOf<NotificationItem> = []
    }

    public enum Action: Sendable {
        case delegate(Delegate)
        case onFirstAppear
        case didLoadItems([NotificationItem])
        case dismiss
        case onMarkAllAsRead
    }

    @Dependency(\.notificationsFeatureClient.log) private var log
    @Dependency(\.notificationsFeatureClient.loadNotifications) private var loadNotifications

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onFirstAppear:
                return loadItems()
            case let .didLoadItems(items):
                state.items = IdentifiedArrayOf(uniqueElements: items)
                return .none
            case .dismiss:
                return .send(.delegate(.dismissNotifications))
            case .delegate:
                return .none
            case .onMarkAllAsRead:
                return .none
            }
        }
    }
}

extension NotificationsFeature {
    public enum Delegate: Sendable, Equatable {
        case dismissNotifications
    }
}

private extension NotificationsFeature {
    private func loadItems() -> Effect<Action> {
        return .run { send in
            let items = try await loadNotifications()
            await send(.didLoadItems(items))
        }
    }
}
