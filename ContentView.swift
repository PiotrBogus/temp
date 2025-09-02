import Foundation
@testable import YourModuleName

public extension CarPlayParkingsSubareaTime {
    static let morning: CarPlayParkingsSubareaTime = .init(display: "08:00", hours: 8, minutes: 0)
    static let afternoon: CarPlayParkingsSubareaTime = .init(display: "14:00", hours: 14, minutes: 0)
    static let evening: CarPlayParkingsSubareaTime = .init(display: "18:00", hours: 18, minutes: 0)
}

public extension CarPlayParkingsSubareaListItem {

    static let fixtureDefault: CarPlayParkingsSubareaListItem = .init(
        name: "Default Zone",
        timeOptions: [.startStop, .minutes15, .hour1],
        tariffId: 1,
        extTariffId: "T1",
        subareaId: 101,
        extSubareaId: "S101",
        startTime: .morning,
        endTime: .afternoon,
        allDay: false
    )

    static let fixtureAllDay: CarPlayParkingsSubareaListItem = .init(
        name: "All Day Zone",
        timeOptions: [.allDay],
        tariffId: 2,
        extTariffId: "T2",
        subareaId: 102,
        extSubareaId: "S102",
        startTime: .morning,
        endTime: .evening,
        allDay: true
    )

    static let fixtureMultiple: [CarPlayParkingsSubareaListItem] = [
        .fixtureDefault,
        .fixtureAllDay,
        .init(
            name: "Evening Zone",
            timeOptions: [.hour2, .hour4],
            tariffId: 3,
            extTariffId: "T3",
            subareaId: 103,
            extSubareaId: "S103",
            startTime: .afternoon,
            endTime: .evening,
            allDay: false
        )
    ]
}
