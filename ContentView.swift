import XCTest
import ComposableArchitecture
@testable import AppCompositionPresentation // lub moduł z NotificationsFeature

@MainActor
final class NotificationsFeatureTests: XCTestCase {

    func testOnFirstAppear_LoadsNotifications() async {
        // Given
        let mockItems = [
            NotificationItem(
                id: "1",
                title: "Welcome",
                description: "Hello User!",
                time: "10:00"
            ),
            NotificationItem(
                id: "2",
                title: "Update",
                description: "New version available.",
                time: "11:30"
            )
        ]

        let store = TestStore(
            initialState: NotificationsFeature.State()
        ) {
            NotificationsFeature()
        } withDependencies: {
            $0.notificationsFeatureClient.loadNotifications = { mockItems }
            $0.notificationsFeatureClient.log = { _, _ in }
        }

        // When
        await store.send(.onFirstAppear)

        // Then
        await store.receive(\.didLoadItems) {
            $0.items = IdentifiedArrayOf(uniqueElements: mockItems)
        }
    }

    func testDidLoadItems_UpdatesState() async {
        // Given
        let items = [
            NotificationItem(
                id: "1",
                title: "Test",
                description: "Message body",
                time: "08:45"
            )
        ]

        let store = TestStore(
            initialState: NotificationsFeature.State()
        ) {
            NotificationsFeature()
        }

        // When / Then
        await store.send(.didLoadItems(items)) {
            $0.items = IdentifiedArrayOf(uniqueElements: items)
        }
    }

    func testDismiss_SendsDelegate() async {
        let store = TestStore(
            initialState: NotificationsFeature.State()
        ) {
            NotificationsFeature()
        } withDependencies: {
            $0.notificationsFeatureClient.loadNotifications = { [] }
            $0.notificationsFeatureClient.log = { _, _ in }
        }

        await store.send(.dismiss)
        await store.receive(\.delegate.dismissNotifications)
    }

    func testOnMarkAllAsRead_DoesNothing() async {
        let store = TestStore(
            initialState: NotificationsFeature.State()
        ) {
            NotificationsFeature()
        }

        await store.send(.onMarkAllAsRead)
        // Brak zmian stanu i efektów ubocznych — test przejdzie jeśli nie wystąpi błąd.
    }
}
