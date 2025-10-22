import XCTest
import ComposableArchitecture
@testable import Genie

@MainActor
final class MainFeatureTests: XCTestCase {

    func testOnFirstAppear_LoadsMenu_Success() async {
        // GIVEN
        let mockMenuItems = [
            MenuItemDto(id: 1, title: "Home", parentId: nil, externalKPIURL: nil),
            MenuItemDto(id: 2, title: "Sales", parentId: nil, externalKPIURL: nil)
        ]

        let store = TestStore(initialState: MainFeature.State()) {
            MainFeature()
        } withDependencies: {
            $0.mainFeatureClient.loadMenu = { mockMenuItems }
        }

        // WHEN
        await store.send(.onFirstAppear)

        // THEN
        await store.receive(\.didLoadMenu) {
            $0.menuItems = mockMenuItems
            $0.didStartToolbarMenuTappedObservation = true
            $0.contentViewState = .content
        }
    }

    func testOnFirstAppear_LoadMenu_Failure() async {
        // GIVEN
        let store = TestStore(initialState: MainFeature.State()) {
            MainFeature()
        } withDependencies: {
            $0.mainFeatureClient.loadMenu = { throw NSError(domain: "test", code: 1) }
        }

        // WHEN
        await store.send(.onFirstAppear)

        // THEN
        await store.receive(\.errorLoadingMenu) {
            $0.contentViewState = .error
        }
    }

    func testDidTapRetry_ReloadsMenu() async {
        let mockMenuItems = [
            MenuItemDto(id: 5, title: "Reports", parentId: nil, externalKPIURL: nil)
        ]

        let store = TestStore(initialState: MainFeature.State()) {
            MainFeature()
        } withDependencies: {
            $0.mainFeatureClient.loadMenu = { mockMenuItems }
        }

        // WHEN
        await store.send(.didTapRetry) {
            $0.contentViewState = .loading
        }

        // THEN
        await store.receive(\.didLoadMenu) {
            $0.menuItems = mockMenuItems
            $0.didStartToolbarMenuTappedObservation = true
            $0.contentViewState = .content
        }
    }

    func testMenuDelegate_DismissMenu() async {
        var state = MainFeature.State()
        state.menu = MenuFeature.State(preselectedItemId: nil, menuItems: [])
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
        state.menu = MenuFeature.State(preselectedItemId: nil, menuItems: [])
        state.isMenuVisible = true

        let store = TestStore(initialState: state) {
            MainFeature()
        }

        await store.send(.menu(.delegate(.didSelectMenuItem(99)))) {
            $0.selectedMenuItemId = 99
            $0.isMenuVisible = false
            $0.menu = nil
        }
    }

    func testUpdateMenuVisibility_False_RemovesMenu() async {
        var state = MainFeature.State()
        state.menu = MenuFeature.State(preselectedItemId: nil, menuItems: [])
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

    func testMainMenuTapped_ShowsMenu() async {
        var state = MainFeature.State()
        state.menuItems = [
            MenuItemDto(id: 1, title: "Home", parentId: nil, externalKPIURL: nil)
        ]
        state.selectedMenuItemId = 1

        let store = TestStore(initialState: state) {
            MainFeature()
        }

        await store.send(.mainMenuTapped) {
            $0.menu = MenuFeature.State(
                preselectedItemId: 1,
                menuItems: [MenuItemDto(id: 1, title: "Home", parentId: nil, externalKPIURL: nil)]
            )
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
