import Foundation
import IKOCommon

final class CarPlayParkingsStopBookingSuccessModel: CarPlayParkingsAlertModel {
    init(
        ticket: CarPlayParkingsTicketListItem,
        resorceProvider: CarPlayParkingsResourceProviding,
        buttonAction: @escaping () -> Void
    ) {
        let message = resorceProvider.stopBookingSuccessMessageText(
            time: ticket.boughtTime(),
            price: ticket.priceWithCurrency()
        ).replacingOccurrences(of: String.newLine, with: String.space)
        let buttonText = resorceProvider.genericButtonOkText
        super.init(alertMessage: message,
                   alertButtonText: buttonText,
                   alertButtonAction: buttonAction)
    }
}
