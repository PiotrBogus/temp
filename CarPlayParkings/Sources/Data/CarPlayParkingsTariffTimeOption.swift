import Foundation

public enum CarPlayParkingsTariffTimeOption: String, Sendable, Equatable {
    case startStop = "START_STOP"
    case minutes15 = "MINUTES_15"
    case minutes30 = "MINUTES_30"
    case hour1 = "HOUR_1"
    case hour2 = "HOUR_2"
    case hour4 = "HOUR_4"
    case hour8 = "HOUR_8"
    case allDay = "ALL_DAY"

    init(minutes: Int) {
        if minutes < 30 {
            self = .minutes15
        } else if minutes < 60 {
            self = .minutes30
        } else if minutes < 120 {
            self = .hour2
        } else if minutes < 240 {
            self = .hour4
        } else if minutes < 480 {
            self = .hour8
        } else {
            self = .allDay
        }
    }
}

public extension CarPlayParkingsTariffTimeOption {
    func toDescription(resourceProvider: CarPlayParkingsTimeOptionsResourceProviding) -> String {
        switch self {
        case .startStop:
            resourceProvider.parkingTimeStartStopText
        case .minutes15:
            resourceProvider.parkingTimeMinutes15Text
        case .minutes30:
            resourceProvider.parkingTimeMinutes30Text
        case .hour1:
            resourceProvider.parkingTimeHour1Text
        case .hour2:
            resourceProvider.parkingTimeHour2Text
        case .hour4:
            resourceProvider.parkingTimeHour4Text
        case .hour8:
            resourceProvider.parkingTimeHour8Text
        case .allDay:
            resourceProvider.parkingTimeAllDayText
        }
    }
}
