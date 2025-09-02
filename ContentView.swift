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
