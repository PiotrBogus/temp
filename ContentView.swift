import XCTest
import ComposableArchitecture
import AppCompositionDomain
@testable import AppCompositionPresentation

@MainActor
final class MenuFeatureTests: XCTestCase {
    func testOnFirstAppear_LoadsMenuAndAppInfo() async {
        let mockMenuItems = [
            MenuItemFeature.State(children: [], id: 1, parentId: nil, title: "Home"),
            MenuItemFeature.State(children: [], id: 2, parentId: nil, title: "Settings")
        ]

        let menuDtos = [
            MenuItem(id: 1, title: "Home", parentId: nil, externalKPIURL: nil),
            MenuItem(id: 2, title: "Settings", parentId: nil, externalKPIURL: nil)
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

        await store.send(.onFirstAppear) {
            $0.appVersion = "1.0"
            $0.appBuild = "100"
            $0.appEnvironment = "Dev"
        }

        await store.receive(\.didBuildMenu) {
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

        await store.receive(\.delegate.didSelectMenuItem)
    }
}




import AppCompositionDomain
import ComposableArchitecture
import GenieCommonPresentation
import Foundation
import SwiftUI

@Reducer
public struct MenuFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        var items: IdentifiedArrayOf<MenuItemFeature.State> = []
        @Shared(.deviceOrientation) var deviceOrientation: DeviceOrientation = .unknown

        public var appVersion: String = ""
        public var appBuild: String = ""
        public var appEnvironment: String = ""

        public init(menuItems: [MenuItemFeature.State]) {
            items = IdentifiedArrayOf(uniqueElements: menuItems)
        }
    }

    public enum Action: Sendable {
        case delegate(Delegate)
        case onFirstAppear
        case dismiss
        case items(IdentifiedActionOf<MenuItemFeature>)

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case dismissMenu
            case didSelectMenuItem(Int)
        }
    }

    @Dependency(\.menuFeatureClient.log) private var log
    @Dependency(\.menuFeatureClient.appInfoViewModel) private var appInfoViewModel

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onFirstAppear:
                log(.debug, "menu did appear for first time")
                if let viewModel = appInfoViewModel() {
                    state.appVersion = viewModel.version
                    state.appBuild = viewModel.build
                    state.appEnvironment = viewModel.environment
                }
                return .none
            case .delegate:
                return .none
            case .dismiss:
                return .send(.delegate(.dismissMenu))
            case let .items(.element(id: _, action: .delegate(.didTapItem(tapModel)))):
                if tapModel.isExpand {
                    keepAncestorsAndCollapseOthers(expandedId: tapModel.id, in: &state.items)
                    return .none
                } else {
                    deselectAllItems(beside: tapModel.id, in: &state.items)
                    return .send(.delegate(.didSelectMenuItem(tapModel.id)))
                }
            case .items:
                return .none
            }
        }
        .forEach(\.items, action: \.items) {
            MenuItemFeature()
        }
    }

    private func deselectAllItems(
        beside id: Int,
        in items: inout IdentifiedArrayOf<MenuItemFeature.State>
    ) {
        for index in items.indices {
            items[index].isSelected = items[index].id == id
            deselectAllItems(beside: id, in: &items[index].identifiedArrayOfChildrens)
        }
    }

    @discardableResult
    private func keepAncestorsAndCollapseOthers(
        expandedId: Int,
        in items: inout IdentifiedArrayOf<MenuItemFeature.State>
    ) -> Bool {
        var found = false
        for index in items.indices {
            if items[index].id == expandedId {
                found = true
                keepAncestorsAndCollapseOthers(
                    expandedId: expandedId,
                    in: &items[index].identifiedArrayOfChildrens
                )
            } else {
                let childHasExpanded = keepAncestorsAndCollapseOthers(
                    expandedId: expandedId,
                    in: &items[index].identifiedArrayOfChildrens
                )

                if childHasExpanded {
                    items[index].isExpanded = true
                    found = true
                } else {
                    items[index].isExpanded = false
                }
            }
        }

        return found
    }
}

