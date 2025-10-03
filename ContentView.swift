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
        @Presents var destination: Destination.State?
        @Presents var menu: MenuFeature.State?

        var selectedMenuItemId: String?
        @Shared(.inMemory(SharedPresentationKeys.toolbarMenuTapped)) var isToolbarMenuTapped: Bool = false

        var content: Content.State
        var didStartToolbarMenuTappedObservation = false

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
        case menu(PresentationAction<MenuFeature.Action>)
        case onAppear
        case onFirstAppear
        case mainMenuTapped
    }

    public var body: some Reducer<State, Action> {
        Scope(state: \.content, action: \.content) {
            Content.body
        }

        Reduce { state, action in
            switch action {
            // --- Bottom bar taps
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

            // --- Content actions
            case .content:
                return .none

            // --- Destination (sheets)
            case .destination:
                return .none

            // --- Menu overlay
            case .menu(.presented(.delegate(.dismissMenu))):
                state.menu = nil
                return .none

            case let .menu(.presented(.delegate(.didSelectMenuItem(id)))):
                state.selectedMenuItemId = id
                state.menu = nil
                return .none

            case .menu:
                return .none

            // --- Lifecycle
            case .onFirstAppear:
                guard !state.didStartToolbarMenuTappedObservation else { return .none }
                state.didStartToolbarMenuTappedObservation = true
                return observeToolbarMenuTapped(state)

            case .onAppear:
                logScreen(.main)
                return .none

            // --- Open menu
            case .mainMenuTapped:
                state.menu = MenuFeature.State(preselectedItemId: state.selectedMenuItemId)
                state.$isToolbarMenuTapped.withLock { $0 = false }
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$menu, action: \.menu)
    }
}

private extension MainFeature {
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
        // 👈 menu usunięte stąd!
    }
}

private enum CancelID { case menu }
