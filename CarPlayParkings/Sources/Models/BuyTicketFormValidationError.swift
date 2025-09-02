import Foundation

enum BuyTicketFormValidationError {
    case carNotSelected
    case areaNotSelected
    case timeOptionNotSelected
    case accountNotSelected

    func toMessage(resourceProvider: CarPlayParkingsResourceProviding) -> String {
        switch self {
        case .carNotSelected:
            resourceProvider.newParkingTicketCarNotSelectedValidationError
        case .areaNotSelected:
            resourceProvider.newParkingTicketAreaNotSelectedValidationError
        case .timeOptionNotSelected:
            resourceProvider.newParkingTicketTimeOptionNotSelectedValidationError
        case .accountNotSelected:
            resourceProvider.newParkingTicketAccountNotSelectedValidationError
        }
    }
}
