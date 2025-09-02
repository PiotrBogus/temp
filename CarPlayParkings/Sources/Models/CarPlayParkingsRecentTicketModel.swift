import Foundation
import IKOCommon

final class CarPlayParkingsRecentTicketModel {
    let title: String
    let description: String

    public init(ticket: CarPlayParkingsTicketListItem, resourceProvider: CarPlayParkingsResourceProviding) {
        let validFrom = NSDate.stringFromDate(ticket.validFromDate, withDateFormat: IKODayMonthYearHourMinuteFormat)
        title = resourceProvider.lastParkingsItemTitleText(time: validFrom.emptyIfNil, location: ticket.locationName)
        var boughtTime: String
        if ticket.isTimeLimited {
            boughtTime = resourceProvider.lastParkingsFixedTimeItemDescriptionText(time: ticket.boughtTime())
        } else {
            boughtTime = resourceProvider.lastParkingsStartStopItemDescriptionText(time: ticket.boughtTime())
        }
        description = boughtTime + .space + resourceProvider.lastParkingsItemPriceText(price: ticket.priceWithCurrency())
    }
}
