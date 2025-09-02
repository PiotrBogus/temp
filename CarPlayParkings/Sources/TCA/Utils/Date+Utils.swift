extension Date {
    static func from(_ timestamp: Int64) -> Date {
        Date(timeIntervalSince1970: Double(timestamp) / 1000)
    }

    func hourMinuteComponents(toDate: Date, dateComponentsProvider: DateComponentsProviding) -> DateComponents {
        dateComponentsProvider.dateComponents([.hour, .minute], from: self, to: toDate)
    }

    func hourMinuteString(toDate: Date, dateComponentsProvider: DateComponentsProviding = Calendar.current) -> String {
        let components = hourMinuteComponents(toDate: toDate, dateComponentsProvider: dateComponentsProvider)
        let hours = components.hour ?? 0
        let hoursText = hours > 0 ? "\(hours) godz " : ""
        let minutes = components.minute ?? 0
        let minutesText = minutes > 0 || hours == 0 ? "\(minutes) min" : ""
        return hoursText + minutesText
    }

    func fullMinutes(toDate: Date, dateComponentsProvider: DateComponentsProviding = Calendar.current) -> Int {
        let components = hourMinuteComponents(toDate: toDate, dateComponentsProvider: dateComponentsProvider)
        var minutes = (components.hour ?? 0) * 60
        minutes += (components.minute ?? 0)
        minutes += (components.second ?? 0) > 0 ? 1 : 0
        return minutes
    }
}
