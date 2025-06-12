
struct CalendarState: Equatable {
    var currentDate: Date = Date()
    var days: [DateValue] = []
    var holidays: Set<Date> = []
    
    var swipeSelection: Int = 1 // 0 = previous, 1 = current, 2 = next
}


enum CalendarAction: Equatable {
    case previousMonth
    case nextMonth
    case updateCalendar
    case swipeChanged(Int)
}


let calendarReducer = Reducer<CalendarState, CalendarAction, CalendarEnvironment> { state, action, env in
    switch action {
    case .previousMonth:
        if let newDate = env.calendar.date(byAdding: .month, value: -1, to: state.currentDate) {
            state.currentDate = newDate
            state.swipeSelection = 1
        }
        return Effect(value: .updateCalendar)

    case .nextMonth:
        if let newDate = env.calendar.date(byAdding: .month, value: 1, to: state.currentDate) {
            state.currentDate = newDate
            state.swipeSelection = 1
        }
        return Effect(value: .updateCalendar)

    case .updateCalendar:
        state.days = generateMonthDates(for: state.currentDate, calendar: env.calendar, holidays: state.holidays)
        return .none

    case let .swipeChanged(index):
        if index == 0 {
            return Effect(value: .previousMonth)
        } else if index == 2 {
            return Effect(value: .nextMonth)
        }
        return .none
    }
}


struct CalendarView: View {
    let store: Store<CalendarState, CalendarAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                Text(formattedMonth(viewStore.currentDate))
                    .font(.title2)
                    .padding(.top)

                TabView(selection: viewStore.binding(
                    get: \.swipeSelection,
                    send: CalendarAction.swipeChanged
                )) {
                    ForEach(0..<3) { index in
                        CalendarMonthView(
                            date: monthOffset(from: viewStore.currentDate, by: index - 1),
                            days: generateMonthDates(
                                for: monthOffset(from: viewStore.currentDate, by: index - 1),
                                calendar: Calendar.current,
                                holidays: viewStore.holidays
                            )
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 400)
            }
            .onAppear {
                viewStore.send(.updateCalendar)
            }
        }
    }

    private func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private func monthOffset(from date: Date, by offset: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: offset, to: date) ?? date
    }
}


struct CalendarMonthView: View {
    let date: Date
    let days: [DateValue]

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 7)

        VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }

                ForEach(days) { dateVal in
                    VStack(spacing: 4) {
                        Text(dateVal.day == -1 ? "" : "\(dateVal.day)")
                            .frame(width: 30, height: 30)
                            .background(isToday(dateVal.date) ? Color.blue : Color.clear)
                            .clipShape(Circle())
                            .foregroundColor(dateVal.day == -1 ? .clear : .primary)

                        if dateVal.isHoliday {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                        } else {
                            Spacer().frame(height: 6)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
