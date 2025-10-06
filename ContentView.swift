//
//  MainView.swift
//

import ComposableArchitecture
import KpiDailySalesPresentation
import KpiIntlMarketTrackerPresentation
import SwiftUI
import UIKit

// MARK: - Overlay window manager for menu

final class MenuOverlayWindow {
    private var window: UIWindow?
    private var animationDuration: TimeInterval = 0.3

    func show<Content: View>(_ view: Content, animated: Bool = true) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let hosting = UIHostingController(rootView: view)
        hosting.view.backgroundColor = .clear
        window.rootViewController = hosting
        window.makeKeyAndVisible()

        if animated {
            window.alpha = 0
            UIView.animate(withDuration: animationDuration) {
                window.alpha = 1
            }
        }

        self.window = window
    }

    func hide(animated: Bool = true) {
        guard let window = window else { return }

        if animated {
            UIView.animate(withDuration: animationDuration, animations: {
                window.alpha = 0
            }, completion: { _ in
                window.isHidden = true
                self.window = nil
            })
        } else {
            window.isHidden = true
            self.window = nil
        }
    }
}

// MARK: - Main View

public struct MainView: View {
    @Bindable var store: StoreOf<MainFeature>
    @State private var overlayWindow = MenuOverlayWindow()

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
        }
        // Show menu overlay in a UIWindow
        .onChange(of: store.menu != nil) { hasMenu in
            if hasMenu {
                showMenuOverlay()
            } else {
                hideMenuOverlay()
            }
        }
    }

    // MARK: - Content
    @ViewBuilder
    var content: some View {
        switch store.scope(state: \.content, action: \.content).case {
        case let .dailySales(store):
            DailySalesNavigationView(store: store)
        case let .intlMarketTracker(store):
            IntlMarketTrackerNavigationView(store: store)
        }
    }

    // MARK: - Overlay handling

    private func showMenuOverlay() {
        guard let menuStore = store.scope(state: \.$menu, action: \.menu) else { return }

        let overlay = MenuOverlayView(
            menuStore: menuStore,
            dismissAction: {
                withAnimation(.easeInOut(duration: menuAnimationDuration)) {
                    isMenuVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + menuAnimationDuration) {
                    store.send(.menu(.presented(.delegate(.dismissMenu))))
                    overlayWindow.hide()
                }
            }
        )

        overlayWindow.show(overlay)
        withAnimation(.easeInOut(duration: menuAnimationDuration)) {
            isMenuVisible = true
        }
    }

    private func hideMenuOverlay() {
        overlayWindow.hide()
    }
}

// MARK: - MenuOverlayView

struct MenuOverlayView: View {
    let menuStore: StoreOf<MainFeature.Menu>
    let dismissAction: () -> Void
    @State private var isVisible: Bool = false
    private let animationDuration: TimeInterval = 0.30

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                Color.black
                    .opacity(isVisible ? 0.5 : 0.0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: animationDuration)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                            dismissAction()
                        }
                    }

                MenuView(store: menuStore)
                    .frame(width: geometry.size.width * 0.75,
                           height: geometry.size.height)
                    .background(Color.white)
                    .shadow(radius: 8)
                    .offset(x: isVisible ? 0 : geometry.size.width)
                    .animation(.easeInOut(duration: animationDuration), value: isVisible)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: animationDuration)) {
                    isVisible = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainView(store: Store(initialState: MainFeature.State()) {
        MainFeature()
    })
}
