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
            
            case .destination(.presented(.menu(.delegate(.dismissMenu)))):
                state.destination = nil
                return .none
                
            case let .destination(.presented(.menu(.delegate(.didSelectMenuItem(id))))):
                state.selectedMenuItemId = id
                state.destination = nil
                return .none

            case .destination:
                return .none

            case .onFirstAppear:
                guard !state.didStartToolbarMenuTappedObservation else { return .none }
                state.didStartToolbarMenuTappedObservation = true
                return observeToolbarMenuTapped(state)
                
            case .onAppear:
                logScreen(.main)
                return .none

            case .mainMenuTapped:
                // TODO: Open main menu
                print(">>> Main menu button tapped")
                state.destination = .menu(MenuFeature.State(preselectedItemId: state.selectedMenuItemId))
                state.$isToolbarMenuTapped.withLock { $0 = false }
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
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
        case menu(MenuFeature)
    }
}

private enum CancelID { case menu }







//
//  MainView.swift
//  Genie
//
//  Created by Daniel Satin on 22.02.2025.
//

import ComposableArchitecture
import KpiDailySalesPresentation
import KpiIntlMarketTrackerPresentation
import SwiftUI

public struct MainView: View {
    @Bindable var store: StoreOf<MainFeature>

    public init(store: StoreOf<MainFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            content
                .toolbar { MainBottomToolbarContent { store.send(.bottomBar($0)) } }
                .onFirstAppear { store.send(.onFirstAppear) }
                .onAppear {
                    store.send(.onAppear)
                }
                .sheet(
                    store: store.scope(state: \.$destination, action: \.destination)
                ) { store in
                    switch store.case {
                    case let .features(store):
                        FeaturesView(store: store)
                    case let .notifications(store):
                        NotificationsView(store: store)
                    case let .profile(store):
                        ProfileView(store: store)
                    case let .search(store):
                        SearchView(store: store)
                    }
                }

            menuView
        }
    }

    @ViewBuilder
    var content: some View {
        switch store.scope(state: \.content, action: \.content).case {
        case let .dailySales(store):
            DailySalesNavigationView(store: store)
        case let .intlMarketTracker(store):
            IntlMarketTrackerNavigationView(store: store)
        }
    }

    var menuView: some View {
        GeometryReader { geometry in
            MenuView(store: store.scope(state: \.menu, action: \.menu))
                .frame(width: geometry.size.width * 0.75,
                       height: geometry.size.height)
                .background(Color.white)
                .offset(x: store.isMenuVisible ? geometry.size.width * 0.25 : geometry.size.width)
                .opacity(store.isMenuVisible ? 1 : 0)
        }
        .animation(.easeIn(duration: 0.5), value: store.isMenuVisible)
    }
}

#Preview {
    MainView(store: Store(initialState: MainFeature.State()) {
        MainFeature()
    })
}
