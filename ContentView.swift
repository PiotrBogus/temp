import ComposableArchitecture
import SwiftUI

struct DatePickerMonthsLayoutView: View {
    enum Constants {
        static let dayHeight: CGFloat = 34
        static let dayViewHeight: CGFloat = dayHeight + publicHolidayDotHeight + verticalSpacing
        static let verticalSpacing: CGFloat = 6
        static let monthHeight: CGFloat = dayViewHeight * 6 + 5 * verticalSpacing
        static let publicHolidayDotHeight: CGFloat = 6
        static let horizontalSpacing: CGFloat = 16
    }
    
    @Bindable var store: StoreOf<DatePickerMonthsLayoutFeature>
    @State private var calendarWidth: CGFloat = .zero
    @State private var scrollProxy: ScrollViewProxy?
    private var isLeftButtonEnabled: Bool {
        guard let index = store.currentVisibleMonthIndex else {
            return false
        }
        return index > 0
    }
    private var isRightButtonEnabled: Bool {
        guard let index = store.currentVisibleMonthIndex else {
            return false
        }
        return index < store.months.count - 1
    }
    private var isLandscape: Bool {
        UIDevice.currentOrientation.isLandscape || UIDevice.currentOrientation == .portraitUpsideDown
    }
    
    public init(
        store: StoreOf<DatePickerMonthsLayoutFeature>
    ) {
        self.store = store
    }
    var body: some View {
        HStack {
            Spacer()
            mainView
                .frame(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
            Spacer()
        }
    }
    
    var mainView: some View {
        VStack {
            titleView
                .background(Color.white)
            
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
            .background(Color.white)
            .contentShape(Rectangle())
            
            if isLandscape {
                Group {
                    ScrollView(.vertical, showsIndicators: false) {
                        calendarScrollView
                            .padding(.bottom, Constants.dayViewHeight)
                    }
                    .scrollTargetLayout(isEnabled: true)
                }
            } else {
                calendarScrollView
            }
        }
        .padding(.horizontal, Constants.horizontalSpacing)
    }
    
    private var titleView: some View {
        HStack {
            Text(store.currentVisibleMonth?.title ?? "")
                .font(.system(size: 17, weight: .medium))
            Spacer()
            HStack(spacing: 28) {
                Button(action: {
                    guard isLeftButtonEnabled else { return }
                    scrollToMonth(direction: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .padding(6)
                        .foregroundStyle(isLeftButtonEnabled ? Color.novartisBlue : Color.textLightGray)
                }
                .frame(width: 40)
                .contentShape(Rectangle())
                .onTapGesture {
                    scrollToMonth(direction: -1)
                }
                
                Button(action: {
                    guard isRightButtonEnabled else { return }
                    scrollToMonth(direction: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .padding(6)
                        .foregroundStyle(isRightButtonEnabled ? Color.novartisBlue : Color.textLightGray)
                }
                .frame(width: 40)
                .contentShape(Rectangle())
                .onTapGesture {
                    scrollToMonth(direction: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
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
    }
    
    private var calendarScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal){
                calendarView
            }
            .onPreferenceChange(MonthOffsetPreferenceKey.self) { offsets in
                let screenCenter = UIScreen.main.bounds.midX
                if let closest = offsets.min(by: { abs($0.value - screenCenter) < abs($1.value - screenCenter) }),
                   let month = store.months.first(where: { $0.id == closest.key }) {
                    store.send(.visibleMonthChanged(month))
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
            .onAppear {
                scrollProxy = proxy
                scrollToMonthWihtDefaultDay()
            }
        }
    }
    
    private var calendarView: some View {
        HStack(spacing: .zero) {
            ForEach(store.months) { month in
                monthView(month: month)
            }
        }
        .scrollTargetLayout()
    }
    
    private func monthView(month: CalendarMonth) -> some View {
        VStack(spacing: .zero) {
            VStack(spacing: Constants.verticalSpacing) {
                ForEach(month.weeks){ week in
                    weekView(week: week, weeksMonthCount: month.weeksCount)
                }
                ForEach(0..<(6 - month.weeks.count), id: \.self) { _ in
                    Color.clear
                        .frame(height: Constants.dayViewHeight)
                }
            }
            .frame(width: calendarWidth, height: Constants.monthHeight)
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
    
    private func weekView(week: CalendarWeek, weeksMonthCount: Int) -> some View {
        HStack(spacing:.zero){
            ForEach(week.days){ day in
                dayView(day: day)
            }
        }
        .frame(height: Constants.dayViewHeight)
        .frame(maxWidth: .infinity)
    }
    
    private func dayView(day: CalendarDay) -> some View {
        VStack(spacing: Constants.verticalSpacing) {
            ZStack(alignment: .top) {
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
                    .padding(.bottom, day.isPublicHoliday ? 0 : Constants.publicHolidayDotHeight + Constants.verticalSpacing)
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
    
    private func scrollToMonth(direction: Int) {
        if let currentVisibleMonthIndex = store.currentVisibleMonthIndex {
            let newIndex = currentVisibleMonthIndex + direction
            guard newIndex >= 0, newIndex < store.months.count else { return }
            let newMonth = store.months[newIndex]
            withAnimation {
                scrollProxy?.scrollTo(newMonth.id, anchor: .center)
            }
        }
    }
    
    private func scrollToMonthWihtDefaultDay() {
        if let monthWithDefaultDay = store.months.first(where: { $0.weeks.contains(where: { $0.days.contains(where: { $0.isDefault })})}) {
            scrollProxy?.scrollTo(monthWithDefaultDay.id, anchor: .center)
            store.send(.visibleMonthChanged(monthWithDefaultDay))
        }
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
