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
                .toolbar {
                    MainBottomToolbarContent { store.send(.bottomBar($0)) }
                }
                .onFirstAppear { store.send(.onFirstAppear) }
                .onAppear { store.send(.onAppear) }
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
        IfLetStore(
            store.scope(state: \.$menu, action: \.menu),
            then: { menuStore in
                GeometryReader { geometry in
                    ZStack(alignment: .trailing) {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                store.send(.menu(.dismiss))
                            }

                        MenuView(store: menuStore)
                            .frame(width: geometry.size.width * 0.75,
                                   height: geometry.size.height)
                            .background(Color.white)
                            .transition(.move(edge: .trailing))
                            .shadow(radius: 8)
                    }
                }
                .animation(.easeInOut, value: store.menu)
            }
        )
    }
}

#Preview {
    MainView(store: Store(initialState: MainFeature.State()) {
        MainFeature()
    })
}
