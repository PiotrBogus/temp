import Foundation

public extension CarPlayParkingsTariffTimeOption {
    func calculateEndTime(subarea: CarPlayParkingsTariffWithSubareaProviding, now: Date = Date.now, calendar: Calendar = Calendar.current) -> Int64 {
        var calculatedTimeInSeconds = now.timeIntervalSince1970
        switch self {
        case .minutes15:
            calculatedTimeInSeconds += 15 * 60
        case .minutes30:
            calculatedTimeInSeconds += 30 * 60
        case .hour1:
            calculatedTimeInSeconds += 60 * 60
        case .hour2:
            calculatedTimeInSeconds += 60 * 60 * 2
        case .hour4:
            calculatedTimeInSeconds += 60 * 60 * 4
        case .hour8:
            calculatedTimeInSeconds += 60 * 60 * 8
        case .allDay, .startStop:
            var endTime: Date?
            if let subareaEndTime = subarea.endTime {
                endTime = calendar.date(bySettingHour: Int(subareaEndTime.hours),
                                        minute: Int(subareaEndTime.minutes),
                                        second: 0 as Int,
                                        of: now)
            }
            if let endTime = endTime,
               !subarea.allDay {
                calculatedTimeInSeconds = endTime.timeIntervalSince1970
            }
            var components = DateComponents()
            components.day = 1
            components.second = -1
            let endOfDay = calendar.date(byAdding: components, to: calendar.startOfDay(for: now))!
            calculatedTimeInSeconds = endOfDay.timeIntervalSince1970
        }
        return Int64(calculatedTimeInSeconds * 1000)
    }
}
