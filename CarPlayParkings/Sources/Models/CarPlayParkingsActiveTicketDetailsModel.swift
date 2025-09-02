import Foundation
import IKOCommon

final class CarPlayParkingsActiveTicketDetailsModel {
    let locationTitle: String
    let locationDescription: String
    let durationTitle: String
    let durationDescription: String
    let carTitle: String
    let carDescription: String
    let startTimeTitle: String
    let startTimeDescription: String
    let endTimeTitle: String
    let endTimeDescription: String

    public init(activeTicket: CarPlayParkingsTicketListItem, resourceProvider: CarPlayParkingsResourceProviding) {
        self.locationTitle = activeTicket.locationName
        self.locationDescription = activeTicket.descriptionText
        self.durationTitle = CarPlayParkingsActiveTicketDetailsModel.createDurationTitle(
            activeTicket: activeTicket,
            resourceProvider: resourceProvider
        )
        self.durationDescription = resourceProvider.activeTicketDetailsTimeTypeText
        self.carTitle = activeTicket.plate
        if !activeTicket.plateName.isEmpty {
            self.carDescription = activeTicket.plateName
        } else {
            self.carDescription = resourceProvider.activeTicketDetailsCarText
        }
        if let validFrom = activeTicket.validFromDate {
            self.startTimeTitle = NSDate.stringFromDate(validFrom,
                                                        withDateFormat: IKODayMonthYearHourMinuteFormat)
        } else {
            self.startTimeTitle = .empty
        }
        self.startTimeDescription = resourceProvider.activeTicketDetailsStartTimeText
        if let validTo = activeTicket.validToDate {
            self.endTimeTitle = NSDate.stringFromDate(validTo,
                                                      withDateFormat: IKODayMonthYearHourMinuteFormat)
        } else {
            self.endTimeTitle = .empty
        }
        self.endTimeDescription = resourceProvider.activeTicketDetailsEndTimeText
    }

    private static func createDurationTitle(
        activeTicket: CarPlayParkingsTicketListItem,
        resourceProvider: CarPlayParkingsResourceProviding
    ) -> String {
        if activeTicket.isTimeLimited {
            let boughtTime = activeTicket.boughtTime()
            guard !boughtTime.isEmpty else { return .empty }
            return resourceProvider.activeTicketDetailsFixedParkingTimeText(
                time: boughtTime,
                price: activeTicket.priceWithCurrency()
            )
        }
        return resourceProvider.activeTicketDetailsStartStopTimeText
    }
}
