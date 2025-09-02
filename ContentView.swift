import XCTest
import CarPlay
import Combine
import ComposableArchitecture
@testable import YourModuleName

@MainActor
final class CarPlayAccountSelectionTemplateTests: XCTestCase {

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Test: push list template on didAppear
    func testDidAppear_PushesListTemplate() {
        let coordinator = CarPlayCoordinatorMock()
        let resourceProvider = CarPlayParkingsResourcesMock(selectAccountTitleText: "Select Account")
        
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
        
        // Template został pushnięty
        XCTAssertEqual(coordinator.interfaceControllerMock.pushedTemplates.count, 1)
        let pushed = coordinator.interfaceControllerMock.pushedTemplates.first
        XCTAssertTrue(pushed is CPListTemplate)
        XCTAssertTrue(coordinator.interfaceControllerMock.dismissedAndPushed)
        
        // Sprawdzamy tytuł template
        let listTemplate = pushed as! CPListTemplate
        XCTAssertEqual(listTemplate.title, "Select Account")
        XCTAssertEqual(listTemplate.sections.first?.items.count, store.state.accounts.count)
    }
    
    // MARK: - Test: selecting account sends action and removes template
    func testSelectingAccount_SendsOnAccountSelection() async {
        let coordinator = CarPlayCoordinatorMock()
        let resourceProvider = CarPlayParkingsResourcesMock(selectAccountTitleText: "Select Account")
        
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
        
        // Pobieramy pierwszy item i wywołujemy handler
        let listTemplate = coordinator.interfaceControllerMock.pushedTemplates.first as! CPListTemplate
        let firstItem = listTemplate.sections.first!.items.first!
        
        let exp = expectation(description: "handler completion")
        firstItem.handler?(firstItem, { exp.fulfill() })
        await fulfillment(of: [exp], timeout: 1)
        
        await store.receive(.delegate(.dismissAccountSelection(.fixtureDefault)))
        
        // Template powinien zostać usunięty
        XCTAssertTrue(coordinator.removed.contains { $0 as AnyObject === firstItem })
    }
    
    // MARK: - Test: didPop triggers didPop action and clears mainTemplate
    func testDidPop_SendsDidPop() async {
        let coordinator = CarPlayCoordinatorMock()
        let resourceProvider = CarPlayParkingsResourcesMock(selectAccountTitleText: "Select Account")
        
        let store = TestStore(
            initialState: .fixtureWithAccounts,
            reducer: { CarPlayAccountSelectionReducer() }
        )
        
        var templateRef: CPListTemplate? = nil
        withDependencies {
            $0.carPlayCoordinator = coordinator
            $0.carPlayResourceProvider = resourceProvider
        } operation: {
            let template = CarPlayAccountSelectionTemplate(store: store)
            // Pobieramy mainTemplate dla sprawdzenia
            templateRef = template.mainTemplate as? CPListTemplate
        }
        
        // symulacja, że template zniknął z interfejsu
        coordinator.containsTemplates = []
        if let template = templateRef {
            coordinator.simulateDidPop(template: template)
        }
        
        await store.receive(.didPop)
    }
}
