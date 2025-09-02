import Foundation

public final class CarPlayParkingsActiveTicketOverviewModel: Sendable, Equatable {
    let title: String
    let remainingTimeLabel: String
    let validTo: Date?
    let calendar: DateComponentsProviding
    var remainingTime: String {
        if let validTo = validTo {
            Date.now.hourMinuteString(toDate: validTo, dateComponentsProvider: calendar)
        } else {
            .empty
        }
    }

    public init(
        activeTicket: CarPlayParkingsTicketListItem,
        resorceProvider: CarPlayParkingsResourceProviding,
        calendar: DateComponentsProviding = Calendar.current
    ) {
        self.title = resorceProvider.activeTicketOverviewTitleText
        self.remainingTimeLabel = resorceProvider.activeTicketOverviewDescriptionText
        self.validTo = activeTicket.validToDate
        self.calendar = calendar
    }

    public func timeIsUp() -> Bool {
            validTo != nil ? Date.now >= validTo! : true
    }

    public static func == (lhs: CarPlayParkingsActiveTicketOverviewModel, rhs: CarPlayParkingsActiveTicketOverviewModel) -> Bool {
        lhs.title == rhs.title &&
        lhs.remainingTimeLabel == rhs.remainingTimeLabel &&
        lhs.validTo == rhs.validTo &&
        lhs.remainingTime == rhs.remainingTime
    }
}
