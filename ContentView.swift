import XCTest
import ComposableArchitecture
@testable import YourModuleName // 🔹 Zamień na nazwę swojego modułu

@MainActor
final class MenuItemFeatureTests: XCTestCase {

    func testTapExpandableItem_TogglesExpansion() async {
        // Given
        let child = MenuItemFeature.State(children: [], id: "c1", parentId: "p1", title: "Child")
        let item = MenuItemFeature.State(children: [child], id: "p1", parentId: nil, title: "Parent")

        let store = TestStore(initialState: item) {
            MenuItemFeature()
        } withDependencies: {
            $0.menuItemFeatureClient.log = { _, _ in }
        }

        // When
        await store.send(.onAppear) {
            $0.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: $0.children)
        }

        await store.send(.didTapItem(id: "p1")) {
            $0.isExpanded = true
        }

        // Then
        await store.receive(\.delegate.didTapItem, MenuItemTapModel(id: "p1", isExpand: true))
    }

    func testTapLeafItem_TogglesSelection() async {
        // Given
        let item = MenuItemFeature.State(children: [], id: "leaf1", parentId: nil, title: "Leaf")

        let store = TestStore(initialState: item) {
            MenuItemFeature()
        } withDependencies: {
            $0.menuItemFeatureClient.log = { _, _ in }
        }

        // When
        await store.send(.didTapItem(id: "leaf1")) {
            $0.isSelected = true
        }

        // Then
        await store.receive(\.delegate.didTapItem, MenuItemTapModel(id: "leaf1", isExpand: false))
    }
}
