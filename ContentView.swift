import XCTest
import ComposableArchitecture
import AppCompositionDomain
@testable import AppCompositionPresentation

@MainActor
final class MainFeatureTests: XCTestCase {
    func testOnFirstAppear_LoadsMenu_Success() async {
        let mockMenuItems = [
            MenuItemFeature.State(id: 1, parentId: nil, title: "Home"),
            MenuItemFeature.State(id: 2, parentId: nil, title: "Sales")
        ]

        let store = TestStore(initialState: MainFeature.State()) {
            MainFeature()
        } withDependencies: {
            $0.mainFeatureClient.loadMenu = { } // symulacja bez błędu
            $0.mainFeatureClient.buildMenuTree = { _ in mockMenuItems }
        }

        await store.send(.onFirstAppear)
        await store.receive(\.didLoadMenu)
    }

    func testOnFirstAppear_LoadMenu_Failure() async {
        let store = TestStore(initialState: MainFeature.State()) {
            MainFeature()
        } withDependencies: {
            $0.mainFeatureClient.loadMenu = { throw NSError(domain: "test", code: 1) }
        }

        await store.send(.onFirstAppear)
        await store.receive(\.errorLoadingMenu) {
            $0.contentViewState = .error
        }
    }

    func testDidTapRetry_ReloadsMenu() async {
        let mockMenuItems = [
            MenuItemFeature.State(id: 5, parentId: nil, title: "Reports")
        ]

        let store = TestStore(initialState: MainFeature.State()) {
            MainFeature()
        } withDependencies: {
            $0.mainFeatureClient.loadMenu = { }
            $0.mainFeatureClient.buildMenuTree = { _ in mockMenuItems }
        }

        await store.send(.didTapRetry) {
            $0.contentViewState = .loading
        }

        await store.receive(\.didLoadMenu)
    }

    func testMenuDelegate_DismissMenu() async {
        var state = MainFeature.State()
        state.menu = MenuFeature.State(menuItems: [])
        state.isMenuVisible = true

        let store = TestStore(initialState: state) {
            MainFeature()
        }

        await store.send(.menu(.delegate(.dismissMenu))) {
            $0.isMenuVisible = false
            $0.menu = nil
        }
    }

    func testMenuDelegate_DidSelectMenuItem() async {
        var state = MainFeature.State()
        state.menu = MenuFeature.State(menuItems: [])
        state.isMenuVisible = true

        let store = TestStore(initialState: state) {
            MainFeature()
        }

        await store.send(.menu(.delegate(.didSelectMenuItem(id: 99)))) {
            $0.selectedMenuItemId = 99
            $0.isMenuVisible = false
            $0.menu = nil
        }
    }

    func testUpdateMenuVisibility_False_RemovesMenu() async {
        var state = MainFeature.State()
        state.menu = MenuFeature.State(menuItems: [])
        state.isMenuVisible = true

        let store = TestStore(initialState: state) {
            MainFeature()
        }

        await store.send(.updateMenuVisibility(false)) {
            $0.isMenuVisible = false
            $0.menu = nil
        }
    }

    func testBottomBar_Taps_ShowDestinations() async {
        let store = TestStore(initialState: MainFeature.State()) {
            MainFeature()
        }

        await store.send(.bottomBar(.featuresTapped)) {
            $0.destination = .features(FeaturesFeature.State())
        }

        await store.send(.bottomBar(.notificationsTapped)) {
            $0.destination = .notifications(NotificationsFeature.State())
        }

        await store.send(.bottomBar(.profileTapped)) {
            $0.destination = .profile(ProfileFeature.State())
        }

        await store.send(.bottomBar(.searchTapped)) {
            $0.destination = .search(SearchFeature.State())
        }
    }

    func testMainMenuTapped_BuildsMenuTree() async {
        let mockMenuItems = [
            MenuItemFeature.State(id: 1, parentId: nil, title: "Home")
        ]

        var state = MainFeature.State()
        state.selectedMenuItemId = 1

        let store = TestStore(initialState: state) {
            MainFeature()
        } withDependencies: {
            $0.mainFeatureClient.buildMenuTree = { _ in mockMenuItems }
        }

        await store.send(.mainMenuTapped)
        await store.receive(\.didBuildMenuTree) {
            $0.menu = MenuFeature.State(menuItems: mockMenuItems)
        }
    }

    func testErrorLoadingMenu_SetsErrorState() async {
        let store = TestStore(initialState: MainFeature.State()) {
            MainFeature()
        }

        await store.send(.errorLoadingMenu) {
            $0.contentViewState = .error
        }
    }
}
