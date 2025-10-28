//
//  MainFeature.swift
//  Genie
//
//  Created by Daniel Satin on 17.06.2025.
//

import ComposableArchitecture
import KpiDailySalesPresentation
import KpiIntlMarketTrackerPresentation
import GenieCommonPresentation

@Reducer
public struct MainFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        enum ContentViewState: Equatable, Sendable {
            case loading
            case error
            case content
        }

        @Presents var destination: Destination.State?
        var menu: MenuFeature.State?
        var selectedMenuItemId: Int?

        @Shared(.inMemory(SharedPresentationKeys.toolbarMenuTapped)) var isToolbarMenuTapped: Bool = false
        @Shared(.deviceOrientation) var deviceOrientation: DeviceOrientation = .unknown

        var content: Content.State
        var didStartToolbarMenuTappedObservation = false
        // used for animation purpose 
        var isMenuVisible: Bool = false
        var contentViewState: ContentViewState = .loading

        public init(
            content: Content.State = .intlMarketTracker(.init())
        ) {
            self.content = content
        }
    }

    public enum Action: Sendable {
        case bottomBar(BottomBarAction)
        case content(Content.Action)
        case destination(PresentationAction<Destination.Action>)
        case didLoadMenu
        case didBuildMenuTree([MenuItemFeature.State])
        case didTapRetry
        case errorLoadingMenu
        case mainMenuTapped
        case menu(MenuFeature.Action)
        case onAppear
        case onFirstAppear
        case updateMenuVisibility(Bool)
    }

    @Dependency(\.mainFeatureClient) private var mainFeatureClient

    public var body: some Reducer<State, Action> {
        Scope(state: \.content, action: \.content) {
            Content.body
        }

        Reduce { state, action in
            switch action {
            case .bottomBar(.featuresTapped):
                state.destination = .features(FeaturesFeature.State())
                return .none

            case .bottomBar(.notificationsTapped):
                state.destination = .notifications(NotificationsFeature.State())
                return .none

            case .bottomBar(.profileTapped):
                state.destination = .profile(ProfileFeature.State())
                return .none

            case .bottomBar(.searchTapped):
                state.destination = .search(SearchFeature.State())
                return .none

            case .content:
                return .none

            case .destination(.presented(.notifications(.delegate(.dismissNotifications)))):
                state.destination = nil
                return .none

            case .destination:
                return .none

            case .didLoadMenu:
                guard !state.didStartToolbarMenuTappedObservation else { return .none }
                state.didStartToolbarMenuTappedObservation = true
                state.contentViewState = .content
                return observeToolbarMenuTapped(state)

            case let .didBuildMenuTree(menuItems):
                state.menu = MenuFeature.State(menuItems: menuItems)
                return .none

            case .didTapRetry:
                state.contentViewState = .loading
                return loadMenu()

            case .errorLoadingMenu:
                state.contentViewState = .error
                return .none

            case .mainMenuTapped:
                state.$isToolbarMenuTapped.withLock { $0 = false }
                return buildMenuTree(selectedItemId: state.selectedMenuItemId)

            case .menu(.delegate(.dismissMenu)):
                state.isMenuVisible = false
                state.menu = nil
                return .none

            case let .menu(.delegate(.didSelectMenuItem(id))):
                state.selectedMenuItemId = id
                state.isMenuVisible = false
                state.menu = nil
                return .none

            case .menu:
                return .none

            case .onAppear:
                logScreen(.main)
                return .none

            case .onFirstAppear:
                return loadMenu()

            case let .updateMenuVisibility(isVisible):
                state.isMenuVisible = isVisible
                if !isVisible {
                    state.menu = nil
                }
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.menu, action: \.menu) {
            MenuFeature()
        }
    }
}

private extension MainFeature {
    func loadMenu() -> Effect<Action> {
        .run { send in
            do {
                try await mainFeatureClient.loadMenu()
                await send(.didLoadMenu)
            } catch {
                await send(.errorLoadingMenu)
            }
        }
    }

    func buildMenuTree(selectedItemId: Int?) -> Effect<Action> {
        .run { send in
            let menuItems = try await mainFeatureClient.buildMenuTree(selectedItemId)
            await send(.didBuildMenuTree(menuItems))
        }
    }

    func observeToolbarMenuTapped(_ state: State) -> Effect<Action> {
        .publisher {
            state.$isToolbarMenuTapped.publisher
                .removeDuplicates()
                .filter { $0 }
                .map { _ in .mainMenuTapped }
                .eraseToAnyPublisher()
        }
        .cancellable(id: CancelID.menu, cancelInFlight: true)
    }
}

extension MainFeature {
    public enum BottomBarAction: Sendable {
        case featuresTapped
        case notificationsTapped
        case profileTapped
        case searchTapped
    }

    @Reducer(state: .equatable, .sendable, action: .sendable)
    public enum Content {
        case dailySales(DailySalesNavigationFeature)
        case intlMarketTracker(IntlMarketTrackerNavigationFeature)
    }

    @Reducer(state: .sendable, .equatable, action: .sendable)
    public enum Destination {
        case features(FeaturesFeature)
        case notifications(NotificationsFeature)
        case profile(ProfileFeature)
        case search(SearchFeature)
    }
}

private enum CancelID { case menu }






import XCTest
import ComposableArchitecture
import AppCompositionDomain
@testable import AppCompositionPresentation

@MainActor
final class MainFeatureTests: XCTestCase {
    func testOnFirstAppear_LoadsMenu_Success() async {
        let mockMenuItems = [
            MenuItem(id: 1, title: "Home", parentId: nil, externalKPIURL: nil),
            MenuItem(id: 2, title: "Sales", parentId: nil, externalKPIURL: nil)
        ]

        let store = TestStore(initialState: MainFeature.State()) {
            MainFeature()
        } withDependencies: {
            $0.mainFeatureClient.loadMenu = { mockMenuItems }
        }
        store.exhaustivity = .off

        await store.send(.onFirstAppear)

        await store.receive(\.didLoadMenu) {
            $0.menuItems = mockMenuItems
            $0.didStartToolbarMenuTappedObservation = true
            $0.contentViewState = .content
        }
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
            MenuItem(id: 5, title: "Reports", parentId: nil, externalKPIURL: nil)
        ]

        let store = TestStore(initialState: MainFeature.State()) {
            MainFeature()
        } withDependencies: {
            $0.mainFeatureClient.loadMenu = { mockMenuItems }
        }
        store.exhaustivity = .off

        await store.send(.didTapRetry) {
            $0.contentViewState = .loading
        }

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
            MenuItem(id: 1, title: "Home", parentId: nil, externalKPIURL: nil)
        ]
        state.selectedMenuItemId = 1

        let store = TestStore(initialState: state) {
            MainFeature()
        }

        await store.send(.mainMenuTapped) {
            $0.menu = MenuFeature.State(
                preselectedItemId: 1,
                menuItems: [MenuItem(id: 1, title: "Home", parentId: nil, externalKPIURL: nil)]
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
