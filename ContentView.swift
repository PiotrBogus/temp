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
