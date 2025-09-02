import Foundation

public typealias CarPlayParkingsResources = CarPlayParkingsResourceProviding & CarPlayParkingsTimeOptionsResourceProviding

public protocol CarPlayParkingsResourceProviding {
    var alertButtonTryAgainText: String { get }
    var loadingSplashText: String { get }
    var determiningLocationText: String { get }
    var mobiletNotFoundText: String { get }
    var locationDisabledText: String { get }
    var activeTicketOverviewDescriptionText: String { get }
    var activeTicketOverviewTitleText: String { get }
    var activeTicketOverviewStopButtonText: String { get }
    var activeTicketDetailsTitleText: String { get }
    var activeTicketDetailsStartStopTimeText: String { get }
    var activeTicketDetailsTimeTypeText: String { get }
    var activeTicketDetailsCarText: String { get }
    var activeTicketDetailsStartTimeText: String { get }
    var activeTicketDetailsEndTimeText: String { get }
    var activeTicketDetailsStopText: String { get }
    var confirmStopParkingTitleText: String { get }
    var confirmStopParkingYesButtonText: String { get }
    var confirmStopParkingNoButtonText: String { get }
    var processingStopActiveParkingText: String { get }
    var genericButtonOkText: String { get }
    var selectCityTitleText: String { get }
    var unknownErrorText: String { get }
    var parkingZoneText: String { get }
    var selectText: String { get }
    var newParkingFormTitleText: String { get }
    var newParkingTimeTypeTitleText: String { get }
    var newParkingCarTitleText: String { get }
    var selectParkingZoneText: String { get }
    var startStopRowTitleText: String { get }
    var startStopRowDescriptionText: String { get }
    var selectParkingTimeTypeText: String { get }
    var selectFixedParkingTimeTypeText: String { get }
    var selectParkingTimeFixedTimeTitleText: String { get }
    var selectParkingTimeFixedTimeDescrText: String { get }
    var selectCarTitleText: String { get }
    var newParkingAccountTitleText: String { get }
    var selectAccountTitleText: String { get }
    var nextButtonText: String { get }
    var confirmationParkingTimeTypeText: String { get }
    var confirmationParkingTitleText: String { get }
    var confirmationParkingCarText: String { get }
    var confirmationParkingAccountText: String { get }
    var confirmationParkingAcceptText: String { get }
    var authNewStartStopParkingSuccessText: String { get }
    var authNewParkingFixedTimeSuccessText: String { get }
    var preauthNewParkingProcessingText: String { get }
    var authNewParkingProcessingText: String { get }
    var noActiveParkingSelectCityEmptyText: String { get }
    var noActiveParkingSelectZoneEmptyText: String { get }
    var appBlockedText: String { get }
    var lastParkingsTitleText: String { get }
    var lastParkingsTicketDetailStartStopText: String { get }
    var lastParkingsTicketDetailsParkingTypeText: String { get }
    var lastParkingsTicketDetailsCarText: String { get }
    var lastParkingsTicketDetailsStrtTimeText: String { get }
    var lastParkingsTicketDetailsEndTimeText: String { get }
    var lastParkingsTicketDetailsTitleText: String { get }
    var lastParkingsTicketDetailsRepeatText: String { get }
    var lastParkingTicketRepeatProcessingText: String { get }
    var lastParkingTicketRepeatNoActiveTypesText: String { get }
    var findZoneByGpsLoadingText: String { get }
    var serviceProviderText: String { get }
    var newParkingTabTitleText: String { get }
    var historyTabTitleText: String { get }
    var newParkingTicketValidationErrorTitle: String { get }
    var newParkingTicketCarNotSelectedValidationError: String { get }
    var newParkingTicketAreaNotSelectedValidationError: String { get }
    var newParkingTicketTimeOptionNotSelectedValidationError: String { get }
    var newParkingTicketAccountNotSelectedValidationError: String { get }

    func activeTicketDetailsFixedParkingTimeText(time: String, price: String) -> String
    func stopBookingSuccessMessageText(time: String, price: String) -> String
    func parkingTimeWithPriceText(time: String, price: String) -> String
    func lastParkingsItemTitleText(time: String, location: String) -> String
    func lastParkingsFixedTimeItemDescriptionText(time: String) -> String
    func lastParkingsStartStopItemDescriptionText(time: String) -> String
    func lastParkingsItemPriceText(price: String) -> String
    func lastParkingsTicketDetailsForFixedTimeText(time: String, price: String) -> String
}
