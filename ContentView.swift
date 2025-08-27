  private func organizeDatesIntoMonthWeekDayGroups(pickerDates: [PickerDate]) -> [CalendarMonth] {
        let calendar = Calendar(identifier: .gregorian)
        let sortedPickerDates = pickerDates.sorted { $0.date < $1.date }
        let inputDateSet = Set(sortedPickerDates) // For quick lookup to see which dates were in the original array

        // Step 1: Identify all unique months present in the input dates
        var monthsSet = Set<String>()
        var monthComponentsList: [(year: Int, month: Int)] = []

        for pickerDate in inputDateSet {
            let comps = calendar.dateComponents([.year, .month], from: pickerDate.date)
            if let year = comps.year, let month = comps.month {
                let key = String(format: "%04d-%02d", year, month)
                // Avoid duplicates by using a set
                if !monthsSet.contains(key) {
                    monthsSet.insert(key)
                    monthComponentsList.append((year, month))
                }
            }
        }

        var result: [CalendarMonth] = []

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
            var weekMap: [Int: [CalendarDay]] = [:]

            for date in allDays {
                let weekOfMonth = calendar.component(.weekOfMonth, from: date)
                // find pickerDate same as date
                let pickerDate = inputDateSet.first { Calendar.isSameDay($0.date, date) }

                let dayGroup = CalendarDay(
                    date: date,
                    isSelected: pickerDate?.isSelected ?? false,
                    isEnabled: pickerDate?.isEnabled ?? false,
                    isPublicHoliday: pickerDate?.isPublicHoliday ?? false,
                    publicHolidayTitle: pickerDate?.publicHolidayTitle,
                    publicHolidayDescription: pickerDate?.publicHolidayDescription,
                    isDefault: pickerDate?.isDefault ?? false,
                    hasAlternateData: pickerDate?.hasAlternateData ?? false,
                    isAlternateData: pickerDate?.isAlternateData ?? false
                )

                // Append to the correct week bucket
                if weekMap[weekOfMonth] == nil {
                    weekMap[weekOfMonth] = []
                }

                weekMap[weekOfMonth]?.append(dayGroup)
            }

            // Step 5: Convert week map into sorted WeekGroup objects
            var weekGroups: [CalendarWeek] = []
            for (weekNum, dayGroups) in weekMap {
                // Sort days within the week
                var sortedDays = dayGroups.sorted(by: { $0.date ?? Date(timeIntervalSinceNow: 1) < $1.date ?? Date(timeIntervalSinceNow: 1) })
                // Fill with empty data when week doesnt have 7 days
                while sortedDays.count < 7 {
                    sortedDays.insert(
                        .init(
                            date: nil,
                            isSelected: false,
                            isEnabled: false,
                            isPublicHoliday: false,
                            publicHolidayTitle: nil,
                            publicHolidayDescription: nil,
                            isDefault: false,
                            hasAlternateData: false,
                            isAlternateData: false
                        ),
                        at: sortedDays.contains(
                            where: {
                                guard let date = $0.date else { return false }
                                return Calendar.isFirstDayOfMonth(date)
                            }) ? 0 : sortedDays.endIndex
                    )
                }
                weekGroups.append(CalendarWeek(weekOfMonth: weekNum, days: sortedDays))
            }

            // Sort weeks within the month
            weekGroups.sort()

            // Step 6: Construct the MonthGroup and add it to result
            let monthGroup = CalendarMonth(year: year, month: month, weeks: weekGroups)
            result.append(monthGroup)
        }
        // Step 7: Remove whole month if atleast one day isn't selectable
        // Sort all months chronologically
        return result.filter {
            $0.weeks.contains(where: { week in
                week.days.contains(where: { $0.isEnabled }) })
        }.sorted()
    }
