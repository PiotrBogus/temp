import Foundation

public final class CarPlayParkingsSubareaListItem: CarPlayParkingsTariffWithSubareaProviding, Sendable, Equatable {
    public let tariffId: Int64
    public let extendedTariffId: String
    public let subareaId: Int64
    public let extendedSubareaId: String
    public let name: String
    public let timeOptions: [CarPlayParkingsTariffTimeOption]
    public let startTime: CarPlayParkingsSubareaTime?
    public let endTime: CarPlayParkingsSubareaTime?
    public let allDay: Bool

    public init(name: String,
                timeOptions: [CarPlayParkingsTariffTimeOption],
                tariffId: Int64,
                extTariffId: String,
                subareaId: Int64,
                extSubareaId: String,
                startTime: CarPlayParkingsSubareaTime?,
                endTime: CarPlayParkingsSubareaTime?,
                allDay: Bool) {
        self.tariffId = tariffId
        self.extendedTariffId = extTariffId
        self.subareaId = subareaId
        self.extendedSubareaId = extSubareaId
        self.name = name
        self.timeOptions = timeOptions
        self.startTime = startTime
        self.endTime = endTime
        self.allDay = allDay
    }

    public static func == (lhs: CarPlayParkingsSubareaListItem, rhs: CarPlayParkingsSubareaListItem) -> Bool {
        lhs.tariffId == rhs.tariffId &&
        lhs.extendedTariffId == rhs.extendedTariffId &&
        lhs.subareaId == rhs.subareaId &&
        lhs.extendedSubareaId == rhs.extendedSubareaId &&
        lhs.name == rhs.name &&
        lhs.timeOptions == rhs.timeOptions &&
        lhs.startTime == rhs.startTime &&
        lhs.endTime == rhs.endTime &&
        lhs.allDay == rhs.allDay
    }
}

@objc
public final class CarPlayParkingsSubareaTime: NSObject, @unchecked Sendable {
    let display: String
    let hours: Int64
    let minutes: Int64

    public init(display: String, hours: Int64, minutes: Int64) {
        self.display = display
        self.hours = hours
        self.minutes = minutes
    }
}
