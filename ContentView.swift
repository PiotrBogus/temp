import XCTest
import ComposableArchitecture
@testable import AppCompositionPresentation

@MainActor
final class MenuFeatureTests: XCTestCase {

    func testOnFirstAppear_LoadsMenuAndAppInfo() async {
        // Given
        let mockMenuItems = [
            MenuItemFeature.State(children: [], id: 1, parentId: nil, title: "Home"),
            MenuItemFeature.State(children: [], id: 2, parentId: nil, title: "Settings")
        ]

        let menuDtos = [
            MenuItemDto(id: 1, title: "Home", parentId: nil, externalKPIURL: nil),
            MenuItemDto(id: 2, title: "Settings", parentId: nil, externalKPIURL: nil)
        ]

        let store = TestStore(
            initialState: MenuFeature.State(preselectedItemId: nil, menuItems: menuDtos)
        ) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.buildTreeItems = { _, _ in mockMenuItems }
            $0.menuFeatureClient.appInfoViewModel = {
                AppInfoViewModel(version: "1.0", build: "100", environment: "Dev")
            }
            $0.menuFeatureClient.log = { _, _ in }
        }

        // When
        await store.send(.onFirstAppear) {
            $0.appVersion = "1.0"
            $0.appBuild = "100"
            $0.appEnvironment = "Dev"
        }

        await store.receive(.didBuildMenu(mockMenuItems)) {
            $0.items = IdentifiedArrayOf(uniqueElements: mockMenuItems)
        }
    }

    func testDismiss_SendsDelegate() async {
        let store = TestStore(
            initialState: MenuFeature.State(preselectedItemId: nil, menuItems: [])
        ) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.buildTreeItems = { _, _ in [] }
            $0.menuFeatureClient.log = { _, _ in }
            $0.menuFeatureClient.appInfoViewModel = { nil }
        }

        await store.send(.dismiss)
        await store.receive(.delegate(.dismissMenu))
    }

    func testSelectMenuItem_TriggersDelegate() async {
        // Given
        let item = MenuItemFeature.State(
            children: [],
            id: 1,
            parentId: nil,
            title: "Dashboard",
            isExpanded: false,
            isSelected: false
        )

        let initialState = MenuFeature.State(preselectedItemId: nil, menuItems: [])
        var modifiedState = initialState
        modifiedState.items = [item]

        let store = TestStore(initialState: modifiedState) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.buildTreeItems = { _, _ in [item] }
            $0.menuFeatureClient.log = { _, _ in }
            $0.menuFeatureClient.appInfoViewModel = { nil }
        }

        // When
        await store.send(
            .items(
                .element(
                    id: item.id,
                    action: .delegate(.didTapItem(.init(id: item.id, isExpand: false)))
                )
            )
        ) {
            $0.items[id: item.id]?.isSelected = true
        }

        // Then
        await store.receive(.delegate(.didSelectMenuItem(item.id)))
    }
}
