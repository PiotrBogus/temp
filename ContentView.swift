//
//  MainFeature.swift
//  Genie
//
//  Created by Daniel Satin on 17.06.2025.
//

import AppCompositionData
import ComposableArchitecture
import KpiDailySalesPresentation
import KpiIntlMarketTrackerPresentation
import GenieCommonPresentation

@Reducer
public struct MainFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?
        var menu: MenuFeature.State?
        var menuItems: [MenuItemDto] = []
        var selectedMenuItemId: Int?

        @Shared(.inMemory(SharedPresentationKeys.toolbarMenuTapped)) var isToolbarMenuTapped: Bool = false
        @Shared(.deviceOrientation) var deviceOrientation: DeviceOrientation = .unknown

        var content: Content.State
        var didStartToolbarMenuTappedObservation = false
        // used for animation purpose 
        var isMenuVisible: Bool = false
        var contentViewState: MainViewContentState = .loading

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
        case menu(MenuFeature.Action)
        case onAppear
        case onFirstAppear
        case mainMenuTapped
        case updateMenuVisibility(Bool)
        case didLoadMenu([MenuItemDto])
        case errorLoadingMenu
        case didTapRetry
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

            case .destination:
                return .none

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

            case .onFirstAppear:
                return loadMenu()

            case let .didLoadMenu(menuItems):
                state.menuItems = menuItems
                guard !state.didStartToolbarMenuTappedObservation else { return .none }
                state.didStartToolbarMenuTappedObservation = true
                state.contentViewState = .content
                return observeToolbarMenuTapped(state)

            case .errorLoadingMenu:
                state.contentViewState = .error
                return .none

            case .didTapRetry:
                state.contentViewState = .loading
                return loadMenu()

            case .onAppear:
                logScreen(.main)
                return .none

            case .mainMenuTapped:
                state.menu = MenuFeature.State(
                    preselectedItemId: state.selectedMenuItemId,
                    menuItems: state.menuItems
                )
                state.$isToolbarMenuTapped.withLock { $0 = false }
                return .none
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
                let menuItems = try await mainFeatureClient.loadMenu()
                await send(.didLoadMenu(menuItems))
            } catch {
                await send(.errorLoadingMenu)
            }
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










//
//  MainFeatureClient.swift
//  Genie
//
//  Created by Daniel Satin on 27.06.2025.
//

import Combine
import AppCompositionData
import Dependencies
import DependenciesMacros
import Network

@DependencyClient
struct MainFeatureClient: DependencyKey {
    var networkStatus: @Sendable () async -> AnyPublisher<(isOnline: Bool, status: NWPath.Status), Never> = {
        Just((true, .satisfied))
            .eraseToAnyPublisher()
    }
    var loadMenu: @Sendable () async throws -> [MenuItemDto]

    static let liveValue = MainFeatureClient(
        networkStatus: {
            @Dependency(\.networkSignalRepository) var repository
            return await repository.networkStatusPublisher()
        },
        loadMenu: {
            @Dependency(\.menuRepository) var menuRepository
            return try await menuRepository.loadMenu()
        }
    )
}

extension DependencyValues {
    var mainFeatureClient: MainFeatureClient {
        get { self[MainFeatureClient.self] }
        set { self[MainFeatureClient.self] = newValue }
    }
}

