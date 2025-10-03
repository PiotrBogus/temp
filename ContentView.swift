//
//  MainView.swift
//

import ComposableArchitecture
import KpiDailySalesPresentation
import KpiIntlMarketTrackerPresentation
import SwiftUI

public struct MainView: View {
    @Bindable var store: StoreOf<MainFeature>

    // Local UI state to drive animation
    @State private var isMenuVisible: Bool = false
    private let menuAnimationDuration: TimeInterval = 0.30

    public init(store: StoreOf<MainFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
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

    // MARK: - Menu overlay with push-style animation
    @ViewBuilder
    var menuOverlay: some View {
        IfLetStore(
            store.scope(state: \.$menu, action: \.menu)
        ) { menuStore in
            GeometryReader { geometry in
                ZStack(alignment: .trailing) {
                    // Background that fades in/out driven by isMenuVisible
                    Color.black
                        .opacity(isMenuVisible ? 0.5 : 0.0)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // Animate UI first, then tell the store to remove the menu
                            withAnimation(.easeInOut(duration: menuAnimationDuration)) {
                                isMenuVisible = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + menuAnimationDuration) {
                                // Send the delegate dismiss to the reducer AFTER animation
                                store.send(.menu(.presented(.delegate(.dismissMenu))))
                            }
                        }

                    // The menu itself — offset driven by local state
                    MenuView(store: menuStore)
                        .frame(width: geometry.size.width * 0.75,
                               height: geometry.size.height)
                        .background(Color.white)
                        .shadow(radius: 8)
                        .offset(x: isMenuVisible ? 0 : geometry.size.width)
                        .animation(.easeInOut(duration: menuAnimationDuration), value: isMenuVisible)
                }
                // ensure the overlay is on top
                .zIndex(1)
                .onAppear {
                    // When the menu state appears, animate it in
                    // start off as hidden => then animate to visible
                    isMenuVisible = false
                    withAnimation(.easeInOut(duration: menuAnimationDuration)) {
                        isMenuVisible = true
                    }
                }
                .onDisappear {
                    // reset local UI state
                    isMenuVisible = false
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
