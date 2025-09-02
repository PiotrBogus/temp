import Foundation
import IKOCommon
import ParkingPlaces

public final class CarPlayParkingsTicketListItem: IKOParkingPlacesTicketListItem, CarPlayParkingsTariffWithSubareaProviding, @unchecked Sendable {
    public var extendedTariffId: String {
        extTariffId
    }
    public var extendedSubareaId: String {
        extSubareaId
    }
    public let endTime: CarPlayParkingsSubareaTime?
    public let allDay: Bool
    let isTimeLimited: Bool
    var validToDate: Date? {
        guard let validTo else { return nil }
        return Date.date(from: validTo, dateFormat: .iso8601)
    }
    var validFromDate: Date? {
        guard let validFrom else { return nil }
        return Date.date(from: validFrom, dateFormat: .iso8601)
    }

    @objc
    public init(
        _ parkingTicketId: Int64,
        extParkingTicketId: String,
        locationId: Int64,
        tariffId: Int64,
        extTariffId: String,
        subareaId: Int64,
        extSubareaId: String,
        locationName: String,
        subareaName: String,
        descriptionText: String,
        price: String,
        plate: String,
        plateName: String,
        validFrom: String?,
        validTo: String?,
        isTimeLimited: Bool,
        allDay: Bool
    ) {
        self.endTime = nil
        self.isTimeLimited = isTimeLimited
        self.allDay = allDay
        super.init()
        self.parkingTicketId = parkingTicketId
        self.extParkingTicketId = extParkingTicketId
        self.locationId = locationId
        self.tariffId = tariffId
        self.extTariffId = extTariffId
        self.subareaId = subareaId
        self.extSubareaId = extSubareaId
        self.locationName = locationName
        self.subareaName = subareaName
        self.descriptionText = descriptionText
        self.price = price
        self.plate = plate
        self.plateName = plateName
        self.validFrom = validFrom
        self.validTo = validTo
    }

    public func boughtTime() -> String {
        guard let validFromDate, let validToDate, validFromDate <= validToDate else { return .empty }
        return validFromDate.hourMinuteString(toDate: validToDate)
    }

    public func boughtMinutes() -> Int? {
        guard let validFromDate, let validToDate, validFromDate <= validToDate else { return nil }
        return validFromDate.fullMinutes(toDate: validToDate)
    }

    public func priceWithCurrency() -> String {
        guard !price.isEmpty else { return .empty }
        return price + .space + IKOMoney.defaultCurrency()
    }
}
