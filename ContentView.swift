//
//  DatePickerView.swift
//  BPAGenieV2
//
//  Created by Daniel Satin on 20.03.2025.
//  Copyright © 2025 Novartis. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct DatePickerView: View {
    @SwiftUI.Environment(\.verticalSizeClass) private var verticalSizeClass: UserInterfaceSizeClass?
    @SwiftUI.Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?
    
    private var isLandscape: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }

    enum Constants {
        static let dayViewPickerHeight: CGFloat = 72
    }

    var store: StoreOf<DatePickerFeature>
    var onDragChanged: ((CGFloat) -> Void)?
    @State private var maxLandscapeMonthViewHeight: CGFloat = 0

    @State private var verticalDragOffset: CGFloat = Constants.dayViewPickerHeight
    private var monthViewPickerHeight: CGFloat {
        if isLandscape {
            maxLandscapeMonthViewHeight
        } else {
            400
        }
    }

    public init(
        store: StoreOf<DatePickerFeature>,
        onDragChanged: ((CGFloat) -> Void)? = nil
    ) {
        self.store = store
        self.onDragChanged = onDragChanged
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.white.opacity(0).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.textLightGray)
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)
                    
                    VStack {
                        switch store.calendarType {
                        case .day:
                            DatePickerDaysLayoutView(
                                store: store.scope(
                                    state: \.datePickerDaysLayoutFeature,
                                    action: \.datePickerDaysLayoutFeature
                                )
                            )
                        case .month:
                            DatePickerMonthsLayoutView(
                                store: store.scope(
                                    state: \.datePickerMonthsLayoutFeature,
                                    action: \.datePickerMonthsLayoutFeature
                                )
                            )
                        }
                    }
                    .frame(height: verticalDragOffset)
                    .clipped()
                }
                .background(
                    UnevenRoundedRectangle(
                        cornerRadii: .init(topLeading: 16, topTrailing: 16)
                    )
                    .fill(.white)
                    .ignoresSafeArea()
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: -4)
                )
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            verticalDragOffset -= value.translation.height
                            verticalDragOffset = max(Constants.dayViewPickerHeight,
                                                     min(monthViewPickerHeight, verticalDragOffset))
                            
                            let newType: DatePickerFeature.State.CalendarType =
                            verticalDragOffset <= Constants.dayViewPickerHeight + 100 ? .day : .month
                            store.send(.calendarTypeChanged(newType))
                            onDragChanged?(verticalDragOffset)
                        }
                        .onEnded { _ in
                            withAnimation {
                                verticalDragOffset =
                                verticalDragOffset > monthViewPickerHeight / 3
                                ? monthViewPickerHeight
                                : Constants.dayViewPickerHeight
                            } completion: {
                                let newType: DatePickerFeature.State.CalendarType =
                                verticalDragOffset <= Constants.dayViewPickerHeight + 100 ? .day : .month
                                store.send(.calendarTypeChanged(newType))
                            }
                            onDragChanged?(verticalDragOffset)
                        }
                )
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(edges: .bottom)
        }
        .onSizeClassChange { horizontalSizeClass, verticalSizeClass, size in
            print("maxLandscapeMonthViewHeight")
            print(size)
            maxLandscapeMonthViewHeight = size?.height ?? 0
        }
    }
}

#Preview {
    DatePickerView(
        store: Store(initialState: DatePickerFeature.State()) {
            DatePickerFeature()
        }
    )
}

struct OnSizeClassChangeModifier: ViewModifier {
    @SwiftUI.Environment(\.verticalSizeClass) private var verticalSizeClass: UserInterfaceSizeClass?
    @SwiftUI.Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?
    
    let action: (_ horizontalSizeClass: UserInterfaceSizeClass?, _ verticalSizeClass: UserInterfaceSizeClass?, _ size: CGSize?) -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            action(horizontalSizeClass, verticalSizeClass, geometry.size)
                        }
                        .onChange(of: horizontalSizeClass) { _, _ in
                            action(horizontalSizeClass, verticalSizeClass, geometry.size)
                        }
                        .onChange(of: verticalSizeClass) { _, _ in
                            action(horizontalSizeClass, verticalSizeClass, geometry.size)
                        }
                }
            )
    }
}

extension View {
    public func onSizeClassChange(
        _ action: @escaping (
            _ horizontalSizeClass: UserInterfaceSizeClass?,
            _ verticalSizeClass: UserInterfaceSizeClass?,
            _ size: CGSize?
        ) -> Void
    ) -> some View {
        modifier(
            OnSizeClassChangeModifier(action: action)
        )
    }
}
