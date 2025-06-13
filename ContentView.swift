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

    // Temporary dictionary: [ "YYYY-MM" : [ weekOfMonth : [Date] ] ]
    var monthWeekMap: [String: (year: Int, month: Int, weeks: [Int: [Date]])] = [:]

    for date in sortedDates {
        let comps = calendar.dateComponents([.year, .month, .weekOfMonth], from: date)

        guard let year = comps.year,
              let month = comps.month,
              let weekOfMonth = comps.weekOfMonth else { continue }

        let monthKey = String(format: "%04d-%02d", year, month)

        if monthWeekMap[monthKey] == nil {
            monthWeekMap[monthKey] = (year, month, [:])
        }

        if monthWeekMap[monthKey]!.weeks[weekOfMonth] == nil {
            monthWeekMap[monthKey]!.weeks[weekOfMonth] = []
        }

        monthWeekMap[monthKey]!.weeks[weekOfMonth]?.append(date)
    }

    // Transform to structured MonthGroup → WeekGroup → DayGroup
    var result: [MonthGroup] = []

    for (_, (year, month, weeksDict)) in monthWeekMap {
        var weekGroups: [WeekGroup] = []

        for (weekNumber, datesInWeek) in weeksDict {
            let dayGroups = datesInWeek.sorted().map { DayGroup(date: $0) }
            weekGroups.append(WeekGroup(weekOfMonth: weekNumber, days: dayGroups))
        }

        weekGroups.sort()

        result.append(MonthGroup(year: year, month: month, weeks: weekGroups))
    }

    return result.sorted()
}
