import XCTest
import ComposableArchitecture
import Combine
@testable import YourModuleName

@MainActor
final class CarPlayAccountSelectionTemplateTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    func testDidAppear_PushesListTemplate() {
        let coordinator = CarPlayCoordinatorMock()
        let interfaceController = CarPlayInterfaceControllerMock()
        coordinator.interfaceController = interfaceController
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

        // Oczekujemy, że pushnął się template z listą kont
        XCTAssertEqual(interfaceController.pushedTemplates.count, 1)
        XCTAssertTrue(interfaceController.dismissed)
        XCTAssertTrue(interfaceController.pushedTemplates.first is CPListTemplate)
    }

    func testSelectingAccount_SendsOnAccountSelection() {
        let coordinator = CarPlayCoordinatorMock()
        let interfaceController = CarPlayInterfaceControllerMock()
        coordinator.interfaceController = interfaceController
        let resourceProvider = CarPlayResourceProviderMock()

        let store = TestStore(
            initialState: .fixtureWithAccounts,
            reducer: { CarPlayAccountSelectionReducer() }
        )

        withDependencies {
            $0.carPlayCoordinator = coordinator
            $0.carPlayResourceProvider = resourceProvider
        } operation: {
            let template = CarPlayAccountSelectionTemplate(store: store)
            template // żeby nie ostrzegał o nieużywanej zmiennej
        }

        // wywołujemy handler na pierwszym itemie
        let listTemplate = interfaceController.pushedTemplates.first as! CPListTemplate
        let item = listTemplate.sections.first!.items.first!
        let exp = expectation(description: "handler completion")
        item.handler?(item, { exp.fulfill() })
        wait(for: [exp], timeout: 1)

        store.receive(.delegate(.dismissAccountSelection(.fixtureDefault)))
    }

    func testDidPop_SendsDidPop() {
        let coordinator = CarPlayCoordinatorMock()
        let interfaceController = CarPlayInterfaceControllerMock()
        coordinator.interfaceController = interfaceController
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

        // symulujemy didPop
        coordinator.containsTemplates = [] // udajemy że template zniknął
        coordinator.didPop.send(())

        store.receive(.delegate(.dismissAccountSelection(nil)))
    }
}
