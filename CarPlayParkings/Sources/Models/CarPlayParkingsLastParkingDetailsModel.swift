import Foundation
import IKOCommon

final class CarPlayParkingsLastParkingDetailsModel: Sendable, Equatable {
    let locationTitle: String
    let locationDescription: String
    let durationTitle: String
    let durationDescription: String
    let carTitle: String
    let carDescription: String
    let parkingStartTimeTitle: String
    let parkingStartTimeDescription: String
    let parkingEndTimeTitle: String
    let parkingEndTimeDescription: String

    public init(ticket: CarPlayParkingsTicketListItem, resourceProvider: CarPlayParkingsResourceProviding) {
        locationTitle = ticket.locationName
        locationDescription = ticket.descriptionText
        if ticket.isTimeLimited {
            durationTitle = resourceProvider.lastParkingsTicketDetailsForFixedTimeText(time: ticket.boughtTime(), price: ticket.priceWithCurrency())
        } else {
            durationTitle = resourceProvider.lastParkingsTicketDetailStartStopText
        }
        durationDescription = resourceProvider.lastParkingsTicketDetailsParkingTypeText
        carTitle = ticket.plate
        if !ticket.plateName.isEmpty {
            carDescription = ticket.plateName
        } else {
            carDescription = resourceProvider.lastParkingsTicketDetailsCarText
        }
        if let validFrom = ticket.validFromDate {
            parkingStartTimeTitle = NSDate.stringFromDate(validFrom, withDateFormat: IKODayMonthYearHourMinuteFormat)
        } else {
            parkingStartTimeTitle = .empty
        }
        parkingStartTimeDescription = resourceProvider.lastParkingsTicketDetailsStrtTimeText
        if let validTo = ticket.validToDate {
            parkingEndTimeTitle = NSDate.stringFromDate(validTo, withDateFormat: IKODayMonthYearHourMinuteFormat)
        } else {
            parkingEndTimeTitle = .empty
        }
        parkingEndTimeDescription = resourceProvider.lastParkingsTicketDetailsEndTimeText
    }

    static func == (lhs: CarPlayParkingsLastParkingDetailsModel, rhs: CarPlayParkingsLastParkingDetailsModel) -> Bool {
        lhs.locationTitle == rhs.locationTitle &&
        lhs.locationDescription == rhs.locationDescription &&
        lhs.durationTitle == rhs.durationTitle &&
        lhs.durationDescription == rhs.durationDescription &&
        lhs.carTitle == rhs.carTitle &&
        lhs.carDescription == rhs.carDescription &&
        lhs.parkingStartTimeTitle == rhs.parkingStartTimeTitle &&
        lhs.parkingStartTimeDescription == rhs.parkingStartTimeDescription &&
        lhs.parkingEndTimeTitle == rhs.parkingEndTimeTitle &&
        lhs.parkingEndTimeDescription == rhs.parkingEndTimeDescription
    }
}
