import XCTest
import ComposableArchitecture
import AppCompositionDomain
@testable import AppCompositionPresentation

@MainActor
final class MenuFeatureTests: XCTestCase {
    func testOnFirstAppear_LoadsAppInfo() async {
        let mockMenuItems = [
            MenuItemFeature.State(children: [], id: 1, parentId: nil, title: "Home"),
            MenuItemFeature.State(children: [], id: 2, parentId: nil, title: "Settings")
        ]

        let store = TestStore(
            initialState: MenuFeature.State(menuItems: mockMenuItems)
        ) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.log = { _, _ in }
            $0.menuFeatureClient.appInfoViewModel = {
                AppInfoViewModel(version: "1.0", build: "100", environment: "Dev")
            }
        }

        await store.send(.onFirstAppear) {
            $0.appVersion = "1.0"
            $0.appBuild = "100"
            $0.appEnvironment = "Dev"
        }
    }

    func testDismiss_SendsDelegate() async {
        let store = TestStore(
            initialState: MenuFeature.State(menuItems: [])
        ) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.log = { _, _ in }
            $0.menuFeatureClient.appInfoViewModel = { nil }
        }

        await store.send(.dismiss)
        await store.receive(\.delegate.dismissMenu)
    }

    func testSelectMenuItem_TriggersDelegate() async {
        let item = MenuItemFeature.State(
            children: [],
            id: 1,
            parentId: nil,
            title: "Dashboard",
            isExpanded: false,
            isSelected: false
        )

        let store = TestStore(
            initialState: MenuFeature.State(menuItems: [item])
        ) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.log = { _, _ in }
            $0.menuFeatureClient.appInfoViewModel = { nil }
        }

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

        await store.receive(\.delegate.didSelectMenuItem) {
            // Można tu zweryfikować, że item jest wybrany
            $0.items[id: 1]?.isSelected = true
        }
    }

    func testExpandMenuItem_KeepsExpandedState() async {
        var expandableItem = MenuItemFeature.State(
            children: [
                MenuItemFeature.State(children: [], id: 2, parentId: 1, title: "Child")
            ],
            id: 1,
            parentId: nil,
            title: "Parent",
            isExpanded: false,
            isSelected: false
        )
        expandableItem.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: expandableItem.children)

        let store = TestStore(
            initialState: MenuFeature.State(menuItems: [expandableItem])
        ) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.log = { _, _ in }
            $0.menuFeatureClient.appInfoViewModel = { nil }
        }

        await store.send(
            .items(
                .element(
                    id: 1,
                    action: .delegate(.didTapItem(.init(id: 1, isExpand: true)))
                )
            )
        )
        // brak receive — akcja expand nie emituje efektu, tylko modyfikuje stan
    }
}
