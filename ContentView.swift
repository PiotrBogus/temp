import XCTest
import ComposableArchitecture
@testable import YourModuleName

@MainActor
final class MenuItemFeatureTests: XCTestCase {

    func testTapExpandableItem_TogglesExpansion() async {
        // Given
        let child = MenuItemFeature.State(children: [], id: "c1", parentId: "p1", title: "Child")
        let item = MenuItemFeature.State(children: [child], id: "p1", parentId: nil, title: "Parent", isExpanded: false)

        let store = TestStore(initialState: item) {
            MenuItemFeature()
        } withDependencies: {
            $0.menuItemFeatureClient.log = { _, _ in }
        }

        // When
        await store.send(\.onAppear) {
            $0.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: $0.children)
        }

        await store.send(\.didTapItem, "p1") {
            $0.isExpanded = true // element ma dzieci, więc rozwijamy
        }

        // Then
        await store.receive(\.delegate.didTapItem, ("p1", true))
    }

    func testTapLeafItem_TogglesSelection() async {
        // Given
        let item = MenuItemFeature.State(children: [], id: "leaf1", parentId: nil, title: "Leaf", isSelected: false)

        let store = TestStore(initialState: item) {
            MenuItemFeature()
        } withDependencies: {
            $0.menuItemFeatureClient.log = { _, _ in }
        }

        // When
        await store.send(\.didTapItem, "leaf1") {
            $0.isSelected = true // element bez dzieci — zaznaczany
        }

        // Then
        await store.receive(\.delegate.didTapItem, ("leaf1", false))
    }
}
