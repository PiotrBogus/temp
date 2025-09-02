import CarPlay
import Combine

final class CarPlayCoordinatorMock: CarPlayCoordinator {
    var didPopSubject = PassthroughSubject<CPTemplate, Never>()
    override var didPop: PassthroughSubject<CPTemplate, Never> { didPopSubject }

    var interfaceControllerMock = CarPlayInterfaceControllerMock()
    override var interfaceController: CPInterfaceController? {
        get { interfaceControllerMock }
        set { /* ignorujemy */ }
    }

    private(set) var removedTemplates: [any CarPlayTemplate] = []
    private(set) var appendedTemplates: [any CarPlayTemplate] = []
    private(set) var containsTemplates: Set<CPTemplate> = []

    override func append(_ child: any CarPlayTemplate) {
        appendedTemplates.append(child)
    }

    override func remove(_ child: any CarPlayTemplate) {
        removedTemplates.append(child)
    }

    override func contains(template: CPTemplate) -> Bool {
        containsTemplates.contains { $0 === template }
    }
}



import CarPlay

final class CarPlayInterfaceControllerMock: CPInterfaceController {
    private(set) var pushedTemplates: [CPTemplate] = []
    private(set) var dismissedAndPushed = false

    override func dismissAndPush(template: CPTemplate) {
        dismissedAndPushed = true
        pushedTemplates.append(template)
    }
}






import XCTest
import CarPlay
import Combine
import ComposableArchitecture
@testable import YourModuleName

// MARK: - Mocks

final class CarPlayInterfaceControllerMock: CPInterfaceController {
    private(set) var pushedTemplates: [CPTemplate] = []
    private(set) var dismissedAndPushed = false

    override func dismissAndPush(template: CPTemplate) {
        dismissedAndPushed = true
        pushedTemplates.append(template)
    }
}

final class CarPlayCoordinatorMock: CarPlayCoordinator {
    let didPopSubject = PassthroughSubject<CPTemplate, Never>()
    override var didPop: PassthroughSubject<CPTemplate, Never> { didPopSubject }

    let interfaceControllerMock = CarPlayInterfaceControllerMock()
    override var interfaceController: CPInterfaceController? {
        get { interfaceControllerMock }
        set { /* ignore */ }
    }

    private(set) var removed: [any CarPlayTemplate] = []
    override func remove(_ child: any CarPlayTemplate) {
        removed.append(child)
    }

    var containsTemplates: Set<CPTemplate> = []
    override func contains(template: CPTemplate) -> Bool {
        containsTemplates.contains { $0 === template }
    }
}

struct CarPlayResourceProviderMock: CarPlayResourceProvider {
    var selectAccountTitleText: String = "Select Account"
}

// MARK: - Tests

@MainActor
final class CarPlayAccountSelectionTemplateTests: XCTestCase {
    func testDidAppear_PushesListTemplate() {
        let coordinator = CarPlayCoordinatorMock()
        let resourceProvider = CarPlayResourceProviderMock()

        let store = StoreOf<CarPlayAccountSelectionReducer>(
            initialState: .fixtureWithAccounts,
            reducer: { CarPlayAccountSelectionReducer() }
        )

        withDependencies {
            $0.carPlayCoordinator = coordinator
            $0.carPlayResourceProvider = resourceProvider
        } operation: {
            _ = CarPlayAccountSelectionTemplate(store: store)
        }

        XCTAssertEqual(coordinator.interfaceControllerMock.pushedTemplates.count, 1)
        XCTAssertTrue(coordinator.interfaceControllerMock.dismissedAndPushed)

        let listTemplate = coordinator.interfaceControllerMock.pushedTemplates.first
        XCTAssertTrue(listTemplate is CPListTemplate)
    }

    func testSelectingAccount_SendsOnAccountSelection() async {
        let coordinator = CarPlayCoordinatorMock()
        let resourceProvider = CarPlayResourceProviderMock()

        let store = TestStore(
            initialState: .fixtureWithAccounts,
            reducer: { CarPlayAccountSelectionReducer() }
        )

        withDependencies {
            $0.carPlayCoordinator = coordinator
            $0.carPlayResourceProvider = resourceProvider
        } operation: {
            _ = CarPlayAccountSelectionTemplate(store: store)
        }

        let listTemplate = coordinator.interfaceControllerMock.pushedTemplates.first as! CPListTemplate
        let firstItem = listTemplate.sections.first!.items.first!

        let exp = expectation(description: "handler completion")
        firstItem.handler?(firstItem, { exp.fulfill() })
        await fulfillment(of: [exp], timeout: 1)

        await store.receive(.delegate(.dismissAccountSelection(.fixtureDefault)))
    }

    func testDidPop_SendsDidPop() async {
        let coordinator = CarPlayCoordinatorMock()
        let resourceProvider = CarPlayResourceProviderMock()

        let store = TestStore(
            initialState: .fixtureWithAccounts,
            reducer: { CarPlayAccountSelectionReducer() }
        )

        withDependencies {
            $0.carPlayCoordinator = coordinator
            $0.carPlayResourceProvider = resourceProvider
        } operation: {
            _ = CarPlayAccountSelectionTemplate(store: store)
        }

        // symulujemy że template już nie jest w hierarchii
        coordinator.containsTemplates = []

        let fakeTemplate = CPListTemplate(title: "Fake", sections: [])
        coordinator.didPopSubject.send(fakeTemplate)

        await store.receive(.delegate(.dismissAccountSelection(nil)))
    }
}







@testable import YourModuleName

struct CarPlayParkingsResourcesMock: CarPlayParkingsResources {
    // MARK: - Properties
    var alertButtonTryAgainText: String = "stub_alertButtonTryAgainText"
    var loadingSplashText: String = "stub_loadingSplashText"
    var determiningLocationText: String = "stub_determiningLocationText"
    var mobiletNotFoundText: String = "stub_mobiletNotFoundText"
    var locationDisabledText: String = "stub_locationDisabledText"
    var activeTicketOverviewDescriptionText: String = "stub_activeTicketOverviewDescriptionText"
    var activeTicketOverviewTitleText: String = "stub_activeTicketOverviewTitleText"
    var activeTicketOverviewStopButtonText: String = "stub_activeTicketOverviewStopButtonText"
    var activeTicketDetailsTitleText: String = "stub_activeTicketDetailsTitleText"
    var activeTicketDetailsStartStopTimeText: String = "stub_activeTicketDetailsStartStopTimeText"
    var activeTicketDetailsTimeTypeText: String = "stub_activeTicketDetailsTimeTypeText"
    var activeTicketDetailsCarText: String = "stub_activeTicketDetailsCarText"
    var activeTicketDetailsStartTimeText: String = "stub_activeTicketDetailsStartTimeText"
    var activeTicketDetailsEndTimeText: String = "stub_activeTicketDetailsEndTimeText"
    var activeTicketDetailsStopText: String = "stub_activeTicketDetailsStopText"
    var confirmStopParkingTitleText: String = "stub_confirmStopParkingTitleText"
    var confirmStopParkingYesButtonText: String = "stub_confirmStopParkingYesButtonText"
    var confirmStopParkingNoButtonText: String = "stub_confirmStopParkingNoButtonText"
    var processingStopActiveParkingText: String = "stub_processingStopActiveParkingText"
    var genericButtonOkText: String = "stub_genericButtonOkText"
    var selectCityTitleText: String = "stub_selectCityTitleText"
    var unknownErrorText: String = "stub_unknownErrorText"
    var parkingZoneText: String = "stub_parkingZoneText"
    var selectText: String = "stub_selectText"
    var newParkingFormTitleText: String = "stub_newParkingFormTitleText"
    var newParkingTimeTypeTitleText: String = "stub_newParkingTimeTypeTitleText"
    var newParkingCarTitleText: String = "stub_newParkingCarTitleText"
    var selectParkingZoneText: String = "stub_selectParkingZoneText"
    var startStopRowTitleText: String = "stub_startStopRowTitleText"
    var startStopRowDescriptionText: String = "stub_startStopRowDescriptionText"
    var selectParkingTimeTypeText: String = "stub_selectParkingTimeTypeText"
    var selectFixedParkingTimeTypeText: String = "stub_selectFixedParkingTimeTypeText"
    var selectParkingTimeFixedTimeTitleText: String = "stub_selectParkingTimeFixedTimeTitleText"
    var selectParkingTimeFixedTimeDescrText: String = "stub_selectParkingTimeFixedTimeDescrText"
    var selectCarTitleText: String = "stub_selectCarTitleText"
    var newParkingAccountTitleText: String = "stub_newParkingAccountTitleText"
    var selectAccountTitleText: String = "stub_selectAccountTitleText"
    var nextButtonText: String = "stub_nextButtonText"
    var confirmationParkingTimeTypeText: String = "stub_confirmationParkingTimeTypeText"
    var confirmationParkingTitleText: String = "stub_confirmationParkingTitleText"
    var confirmationParkingCarText: String = "stub_confirmationParkingCarText"
    var confirmationParkingAccountText: String = "stub_confirmationParkingAccountText"
    var confirmationParkingAcceptText: String = "stub_confirmationParkingAcceptText"
    var authNewStartStopParkingSuccessText: String = "stub_authNewStartStopParkingSuccessText"
    var authNewParkingFixedTimeSuccessText: String = "stub_authNewParkingFixedTimeSuccessText"
    var preauthNewParkingProcessingText: String = "stub_preauthNewParkingProcessingText"
    var authNewParkingProcessingText: String = "stub_authNewParkingProcessingText"
    var noActiveParkingSelectCityEmptyText: String = "stub_noActiveParkingSelectCityEmptyText"
    var noActiveParkingSelectZoneEmptyText: String = "stub_noActiveParkingSelectZoneEmptyText"
    var appBlockedText: String = "stub_appBlockedText"
    var lastParkingsTitleText: String = "stub_lastParkingsTitleText"
    var lastParkingsTicketDetailStartStopText: String = "stub_lastParkingsTicketDetailStartStopText"
    var lastParkingsTicketDetailsParkingTypeText: String = "stub_lastParkingsTicketDetailsParkingTypeText"
    var lastParkingsTicketDetailsCarText: String = "stub_lastParkingsTicketDetailsCarText"
    var lastParkingsTicketDetailsStrtTimeText: String = "stub_lastParkingsTicketDetailsStrtTimeText"
    var lastParkingsTicketDetailsEndTimeText: String = "stub_lastParkingsTicketDetailsEndTimeText"
    var lastParkingsTicketDetailsTitleText: String = "stub_lastParkingsTicketDetailsTitleText"
    var lastParkingsTicketDetailsRepeatText: String = "stub_lastParkingsTicketDetailsRepeatText"
    var lastParkingTicketRepeatProcessingText: String = "stub_lastParkingTicketRepeatProcessingText"
    var lastParkingTicketRepeatNoActiveTypesText: String = "stub_lastParkingTicketRepeatNoActiveTypesText"
    var findZoneByGpsLoadingText: String = "stub_findZoneByGpsLoadingText"
    var serviceProviderText: String = "stub_serviceProviderText"
    var newParkingTabTitleText: String = "stub_newParkingTabTitleText"
    var historyTabTitleText: String = "stub_historyTabTitleText"
    var newParkingTicketValidationErrorTitle: String = "stub_newParkingTicketValidationErrorTitle"
    var newParkingTicketCarNotSelectedValidationError: String = "stub_newParkingTicketCarNotSelectedValidationError"
    var newParkingTicketAreaNotSelectedValidationError: String = "stub_newParkingTicketAreaNotSelectedValidationError"
    var newParkingTicketTimeOptionNotSelectedValidationError: String = "stub_newParkingTicketTimeOptionNotSelectedValidationError"
    var newParkingTicketAccountNotSelectedValidationError: String = "stub_newParkingTicketAccountNotSelectedValidationError"

    // MARK: - Functions
    func activeTicketDetailsFixedParkingTimeText(time: String, price: String) -> String {
        "stub_activeTicketDetailsFixedParkingTimeText(\(time), \(price))"
    }

    func stopBookingSuccessMessageText(time: String, price: String) -> String {
        "stub_stopBookingSuccessMessageText(\(time), \(price))"
    }

    func parkingTimeWithPriceText(time: String, price: String) -> String {
        "stub_parkingTimeWithPriceText(\(time), \(price))"
    }

    func lastParkingsItemTitleText(time: String, location: String) -> String {
        "stub_lastParkingsItemTitleText(\(time), \(location))"
    }

    func lastParkingsFixedTimeItemDescriptionText(time: String) -> String {
        "stub_lastParkingsFixedTimeItemDescriptionText(\(time))"
    }

    func lastParkingsStartStopItemDescriptionText(time: String) -> String {
        "stub_lastParkingsStartStopItemDescriptionText(\(time))"
    }

    func lastParkingsItemPriceText(price: String) -> String {
        "stub_lastParkingsItemPriceText(\(price))"
    }

    func lastParkingsTicketDetailsForFixedTimeText(time: String, price: String) -> String {
        "stub_lastParkingsTicketDetailsForFixedTimeText(\(time), \(price))"
    }
}
