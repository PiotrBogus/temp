//
//  MainView.swift
//

import ComposableArchitecture
import KpiDailySalesPresentation
import KpiIntlMarketTrackerPresentation
import SwiftUI

public struct MainView: View {
    @Bindable var store: StoreOf<MainFeature>
    private let overlayWindow = MenuOverlayWindow()

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
        }
        .onChange(of: store.menu != nil) { _, isMenuOverlayVisible in
            if isMenuOverlayVisible {
                showMenuOverlay()
            } else {
                hideMenuOverlay()
            }
        }
    }

    private func showMenuOverlay() {
        overlayWindow.show(menuOverlay)
    }

    private func hideMenuOverlay() {
        overlayWindow.hide()
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
            store.scope(state: \.$menu, action: \.menu)
        ) { menuStore in
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




import SwiftUI

extension View {
    /// Executes an action after a given animation duration.
    func onAnimationCompleted<Value: Equatable>(
        for value: Value,
        duration: Double,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onChange(of: value) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                action()
            }
        }
    }
}
