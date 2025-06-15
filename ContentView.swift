import Foundation

struct DayGroup {
    let date: Date
}

struct WeekGroup: Comparable {
    let weekOfMonth: Int
    var days: [DayGroup]

    static func < (lhs: WeekGroup, rhs: WeekGroup) -> Bool {
        lhs.weekOfMonth < rhs.weekOfMonth
    }
}

struct MonthGroup: Comparable {
    let year: Int
    let month: Int
    var weeks: [WeekGroup]

    static func < (lhs: MonthGroup, rhs: MonthGroup) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        return lhs.month < rhs.month
    }

    var identifier: String {
        String(format: "%04d-%02d", year, month)
    }
}




func organizeDatesIntoMonthWeekDayGroups(dates: [Date]) -> [MonthGroup] {
    let calendar = Calendar.current
    let sortedDates = dates.sorted()
    let inputDateSet = Set(sortedDates) // For quick lookup to see which dates were in the original array

    // Step 1: Identify all unique months present in the input dates
    var monthsSet = Set<String>()
    var monthComponentsList: [(year: Int, month: Int)] = []

    for date in sortedDates {
        let comps = calendar.dateComponents([.year, .month], from: date)
        if let year = comps.year, let month = comps.month {
            let key = String(format: "%04d-%02d", year, month)
            // Avoid duplicates by using a set
            if !monthsSet.contains(key) {
                monthsSet.insert(key)
                monthComponentsList.append((year, month))
            }
        }
    }

    var result: [MonthGroup] = []

    // Step 2: Process each month
    for (year, month) in monthComponentsList {
        // Create a date for the first day of the month
        var components = DateComponents(year: year, month: month, day: 1)
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            continue // Skip if date construction fails
        }

        // Step 3: Generate all dates for the month (1st to last day)
        var allDays: [Date] = []
        for day in range {
            components.day = day
            if let date = calendar.date(from: components) {
                allDays.append(date)
            }
        }

        // Step 4: Group dates by week of the month
        var weekMap: [Int: [DayGroup]] = [:]

        for date in allDays {
            let weekOfMonth = calendar.component(.weekOfMonth, from: date)
            let isOriginal = inputDateSet.contains(date) // Determine if this date was in the original input
            let dayGroup = DayGroup(date: date, isOriginal: isOriginal)

            // Append to the correct week bucket
            if weekMap[weekOfMonth] == nil {
                weekMap[weekOfMonth] = []
            }

            weekMap[weekOfMonth]?.append(dayGroup)
        }

        // Step 5: Convert week map into sorted WeekGroup objects
        var weekGroups: [WeekGroup] = []
        for (weekNum, dayGroups) in weekMap {
            // Sort days within the week
            let sortedDays = dayGroups.sorted(by: { $0.date < $1.date })
            weekGroups.append(WeekGroup(weekOfMonth: weekNum, days: sortedDays))
        }

        // Sort weeks within the month
        weekGroups.sort()

        // Step 6: Construct the MonthGroup and add it to result
        let monthGroup = MonthGroup(year: year, month: month, weeks: weekGroups)
        result.append(monthGroup)
    }

    // Step 7: Sort all months chronologically
    return result.sorted()
}










//
//  DatePickerMonthsLayoutView.swift
//  BPAGenieV2
//
//  Created by Daniel Satin on 30.03.2025.
//  Copyright © 2025 Novartis. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct DatePickerMonthsLayoutView: View {
    enum Constants {
        static let dayHeight: CGFloat = 34
        static let dayViewHeight: CGFloat = dayHeight + publicHolidayDotHeight + verticalSpacing
        static let verticalSpacing: CGFloat = 6
        static let monthHeight: CGFloat = weekHeight * 6 + 5 * verticalSpacing
        static let weekHeight: CGFloat = dayHeight + publicHolidayDotHeight + 6
        static let publicHolidayDotHeight: CGFloat = 6
        static let horizontalSpacing: CGFloat = 16
    }

    @Bindable var store: StoreOf<DatePickerMonthsLayoutFeature>
    @State private var calendarWidth: CGFloat = .zero

    public init(
        store: StoreOf<DatePickerMonthsLayoutFeature>
    ) {
        self.store = store
    }

    var body: some View {
        VStack{
            titleView

            HStack {
                ForEach(store.weekdaysTitles, id: \.self) { title in
                    Text(title.description.uppercased())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.textLightGray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)

                    if title != store.weekdaysTitles.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, Constants.horizontalSpacing)

            ScrollView(.horizontal){
                calendarView
            }
            .onPreferenceChange(MonthOffsetPreferenceKey.self) { offsets in
                let screenCenter = UIScreen.main.bounds.midX
                if let closest = offsets.min(by: { abs($0.value - screenCenter) < abs($1.value - screenCenter) }),
                   let month = store.monthGroups.first(where: { $0.id == closest.key }) {
                    store.send(.visibleMonthChanged(month.title))
                }
            }
            .scrollDisabled(false)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { newValue in
                calendarWidth = newValue
            }
        }
    }
    
    private var titleView: some View {
        HStack{
            Text(store.monthTitle ?? "")
                .font(.system(size: 17, weight: .medium))
            Spacer()
        }
        .padding(.leading, 22)
        .padding(.bottom, 8)
    }
    
    private var weekdaysTitleView: some View {
        HStack{
            ForEach(store.weekdaysTitles, id: \.self) { title in
                Text(title.description.uppercased())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.textLightGray)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)

                if title != store.weekdaysTitles.last {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, Constants.horizontalSpacing)
    }
    
    private var calendarView: some View {
        LazyHStack(alignment: .top, spacing: .zero){
            ForEach(store.monthGroups) { month in
                monthView(month: month)
            }
        }
        .scrollTargetLayout()
        .frame(height: Constants.monthHeight)
    }
    
    private func monthView(month: MonthGroup) -> some View {
        VStack(spacing: .zero) {
            VStack(spacing: Constants.verticalSpacing) {
                ForEach(month.weeks){ week in
                    weekView(week: week, weeksMonthCount: month.weeksCount)
                }
            }
            .frame(width: calendarWidth, height: Constants.monthHeight)
            .onAppear{
                print("Month 🔫 🔫 🔫", month)
            }
        }
        .id(month.id)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: MonthOffsetPreferenceKey.self,
                        value: [month.id: geo.frame(in: .global).midX]
                    )
            }
        )
    }
    
    private func weekView(week: WeekGroup, weeksMonthCount: Int) -> some View {
        HStack(spacing:.zero){
            ForEach(week.days){ day in
                dayView(day: day)
            }
        }
        .padding(.horizontal)
        .frame(height: Constants.weekHeight)
        .frame(maxWidth: .infinity)
    }
    
    private func dayView(day: DayGroup) -> some View {
        VStack(spacing: Constants.verticalSpacing) {
            ZStack {
                if day.isSelected {
                    Circle()
                        .fill(Color.novartisBlue)
                        .frame(width: Constants.dayHeight, height: Constants.dayHeight)
                } else if day.isDefault {
                    Circle()
                        .strokeBorder(Color.novartisBlue, lineWidth: 1)
                        .frame(width: Constants.dayHeight, height: Constants.dayHeight)
                }
                Text(day.title)
                    .foregroundStyle(prepareColorForText(
                        isSelected: day.isSelected,
                        isEnabled: day.isEnabled
                    ))
                    .frame(width: Constants.dayHeight, height: Constants.dayHeight)
            }
            if day.isPublicHoliday {
                Circle()
                    .fill(Color.novartisBlue)
                    .frame(height: Constants.publicHolidayDotHeight)
            }
        }
        .onTapGesture {
            store.send(.didTap(day))
        }
        .frame(height: Constants.dayViewHeight)
        .frame(maxWidth: .infinity)
    }
    
    private func prepareColorForText(isSelected: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else {
            return Color.textLightGray
        }
        return isSelected ? Color.white : Color.black
    }
}

private struct MonthOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

#Preview {
    let selectedDate = Shared<Date?>(value: Date())
    DatePickerMonthsLayoutView(
        store: Store(initialState: DatePickerMonthsLayoutFeature.State(selectedDate: selectedDate)) {
            DatePickerMonthsLayoutFeature()
        }
    )
}

