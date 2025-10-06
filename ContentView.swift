//
//  MainView.swift
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
                NavigationStack {
                    content
                        .toolbar {
                            MainBottomToolbarContent { store.send(.bottomBar($0)) }
                        }
                        .onFirstAppear { store.send(.onFirstAppear) }
                        .onAppear { store.send(.onAppear) }
                        .sheet(
                            store: store.scope(state: \.$destination, action: \.destination)
                        ) { destinationStore in
                            switch destinationStore.case {
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
                }
                
                menuOverlay
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

    @ViewBuilder
    var menuOverlay: some View {
        if let menuStore = store.scope(state: \.$menu, action: \.menu) {
            GeometryReader { geometry in
                ZStack(alignment: .trailing) {
                    Color.black
                        .opacity(store.isMenuVisible ? 0.5 : 0.0)
                        .ignoresSafeArea()
                        .onTapGesture {
                            _ = withAnimation(.easeInOut(duration: 0.3)) {
                                store.send(.menu(.presented(.delegate(.dismissMenu))))
                            }
                        }

                    MenuView(store: menuStore)
                        .frame(
                            width: store.deviceOrientation.isLandscape ? geometry.size.width : geometry.size.width * 0.75,
                            height: geometry.size.height
                        )
                        .background(Color.white)
                        .shadow(radius: 8)
                        .offset(x: store.isMenuVisible ? 0 : geometry.size.width)
                        .animation(.easeInOut(duration: 0.3), value: store.isMenuVisible)
                }
                .onAppear {
                    _ = withAnimation(.easeInOut(duration: 0.3)) {
                        store.send(.updateMenuVisibility(true))
                    }
                }
                .onDisappear {
                    store.send(.updateMenuVisibility(false))
                }
            }
        }
    }
}

#Preview {
    MainView(store: Store(initialState: MainFeature.State()) {
        MainFeature()
    })
}




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
        @Shared(.deviceOrientation) var deviceOrientation: DeviceOrientation = .unknown

        var content: Content.State
        var didStartToolbarMenuTappedObservation = false
        var isMenuVisible: Bool = false

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
        case updateMenuVisibility(Bool)
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

            case .destination:
                return .none

            case .menu(.presented(.delegate(.dismissMenu))):
                state.isMenuVisible = false
                state.menu = nil
                return .none

            case let .menu(.presented(.delegate(.didSelectMenuItem(id)))):
                state.selectedMenuItemId = id
                state.isMenuVisible = false
                state.menu = nil
                return .none

            case .menu:
                return .none

            case .onFirstAppear:
                guard !state.didStartToolbarMenuTappedObservation else { return .none }
                state.didStartToolbarMenuTappedObservation = true
                return observeToolbarMenuTapped(state)

            case .onAppear:
                logScreen(.main)
                return .none

            case .mainMenuTapped:
                state.menu = MenuFeature.State(preselectedItemId: state.selectedMenuItemId)
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
        .ifLet(\.$menu, action: \.menu) {
            MenuFeature()
        }
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
    }
}

private enum CancelID { case menu }




/Users/boguspi2/GenieNG-iOS/Packages/AppComposition/Sources/AppCompositionPresentation/Views/Main/MainView.swift:70:37 Cannot convert value of type 'Store<PresentationState<MenuFeature.State>, PresentationAction<MenuFeature.Action>>' to expected argument type 'StoreOf<MenuFeature>' (aka 'Store<MenuFeature.State, MenuFeature.Action>')
