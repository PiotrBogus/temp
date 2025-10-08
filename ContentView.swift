import XCTest
import ComposableArchitecture
@testable import YourModuleName

final class MenuItemFeatureTests: XCTestCase {

    @MainActor
    func testTapExpandableItem_TogglesExpansion() async {
        let child = MenuItemFeature.State(children: [], id: "c1", parentId: "p1", title: "Child")
        let item = MenuItemFeature.State(children: [child], id: "p1", parentId: nil, title: "Parent", isExpanded: false)

        let store = TestStore(initialState: item) {
            MenuItemFeature()
        } withDependencies: {
            $0.menuItemFeatureClient.log = { _, _ in }
        }

        await store.send(.onAppear) {
            $0.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: $0.children)
        }

        await store.send(.didTapItem(id: "p1")) {
            $0.isExpanded = true // bo ma dzieci
        }
        await store.receive(.delegate(.didTapItem(id: "p1", isExpand: true)))
    }

    @MainActor
    func testTapLeafItem_TogglesSelection() async {
        let item = MenuItemFeature.State(children: [], id: "leaf1", parentId: nil, title: "Leaf", isSelected: false)

        let store = TestStore(initialState: item) {
            MenuItemFeature()
        } withDependencies: {
            $0.menuItemFeatureClient.log = { _, _ in }
        }

        await store.send(.didTapItem(id: "leaf1")) {
            $0.isSelected = true
        }
        await store.receive(.delegate(.didTapItem(id: "leaf1", isExpand: false)))
    }
}
