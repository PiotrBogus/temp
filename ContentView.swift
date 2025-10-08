import XCTest
import ComposableArchitecture
@testable import YourModuleName // <- podmień na nazwę Twojego modułu z MenuFeature

final class MenuFeatureTests: XCTestCase {

    @MainActor
    func testOnFirstAppear_LoadsMenuAndAppInfo() async {
        let mockMenuItems = [
            MenuItemFeature.State(children: [], id: "1", parentId: nil, title: "Home"),
            MenuItemFeature.State(children: [], id: "2", parentId: nil, title: "Settings")
        ]

        let store = TestStore(
            initialState: MenuFeature.State(preselectedItemId: nil)
        ) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.loadMenuItems = { _ in mockMenuItems }
            $0.menuFeatureClient.appInfoViewModel = {
                AppInfoViewModel(version: "1.0", build: "100", environment: "Dev")
            }
            $0.menuFeatureClient.log = { _, _ in }
        }

        await store.send(.onFirstAppear)
        await store.receive(.didLoadMenu(mockMenuItems)) {
            $0.items = IdentifiedArrayOf(uniqueElements: mockMenuItems)
            $0.appVersion = "1.0"
            $0.appBuild = "100"
            $0.appEnvironment = "Dev"
        }
    }

    @MainActor
    func testDismiss_SendsDelegate() async {
        let store = TestStore(initialState: MenuFeature.State(preselectedItemId: nil)) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.loadMenuItems = { _ in [] }
            $0.menuFeatureClient.log = { _, _ in }
            $0.menuFeatureClient.appInfoViewModel = { nil }
        }

        await store.send(.dismiss)
        await store.receive(.delegate(.dismissMenu))
    }

    @MainActor
    func testSelectMenuItem_TriggersDelegate() async {
        let item = MenuItemFeature.State(
            children: [],
            id: "item1",
            parentId: nil,
            title: "Dashboard",
            isExpanded: false,
            isSelected: false
        )

        let initialState = MenuFeature.State(preselectedItemId: nil)
        var modifiedState = initialState
        modifiedState.items = [item]

        let store = TestStore(initialState: modifiedState) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.loadMenuItems = { _ in [item] }
            $0.menuFeatureClient.log = { _, _ in }
            $0.menuFeatureClient.appInfoViewModel = { nil }
        }

        await store.send(.items(.element(id: item.id, action: .delegate(.didTapItem(id: "item1", isExpand: false))))) {
            // deselectAllItems sets isSelected only for tapped ID
            $0.items[id: "item1"]?.isSelected = true
        }
        await store.receive(.delegate(.didSelectMenuItem("item1")))
    }
}



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

