import Foundation

public struct CarPlayParkingsPreauthResponse: Sendable, Equatable {
    public let transactionId: String
    let plate: String
    let locationName: String
    let price: String
    let validFrom: String
    let validFromTimestamp: Int64
    let validTo: String
    let validToTimestamp: Int64

    public init(plate: String,
                locationName: String,
                price: String,
                validFrom: String,
                validFromTimestamp: Int64,
                validTo: String,
                validToTimestamp: Int64,
                transactionId: String) {
        self.plate = plate
        self.locationName = locationName
        self.price = price
        self.validFrom = validFrom
        self.validFromTimestamp = validFromTimestamp
        self.validTo = validTo
        self.validToTimestamp = validToTimestamp
        self.transactionId = transactionId
    }

    public func boughtTime() -> String {
        guard validFromTimestamp <= validToTimestamp else { return "" }
        let validFrom = Date.from(validFromTimestamp)
        let validTo = Date.from(validToTimestamp)
        return validFrom.hourMinuteString(toDate: validTo)
    }
}
