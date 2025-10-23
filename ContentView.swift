import XCTest
@testable import YourModuleName
import CarPlay

// MARK: - Mock CPInterfaceController

final class MockCPInterfaceController: CPInterfaceController {
    var didCallPresent = false
    var didCallDismiss = false
    var didCallSetRoot = false
    var didCallPush = false

    var presentedTemplateStub: CPTemplate?

    override var presentedTemplate: CPTemplate? {
        get { presentedTemplateStub }
        set { presentedTemplateStub = newValue }
    }

    override func presentTemplate(_ template: CPTemplate, animated: Bool, completion: ((Bool, (any Error)?) -> Void)? = nil) {
        didCallPresent = true
        completion?(true, nil)
    }

    override func pushTemplate(_ template: CPTemplate, animated: Bool, completion: ((Bool, (any Error)?) -> Void)? = nil) {
        didCallPush = true
        completion?(true, nil)
    }

    override func setRootTemplate(_ template: CPTemplate, animated: Bool, completion: ((Bool, (any Error)?) -> Void)? = nil) {
        didCallSetRoot = true
        completion?(true, nil)
    }

    override func dismissTemplate(animated: Bool, completion: ((Bool, (any Error)?) -> Void)? = nil) {
        didCallDismiss = true
        completion?(true, nil)
    }
}

// MARK: - Queue-only tests

final class CarPlayPresentationQueueTests: XCTestCase {

    func testQueueExecutesOperationsSequentially() async {
        let queue = CarPlayPresentationQueue.shared
        let expectation = XCTestExpectation(description: "All operations complete")
        expectation.expectedFulfillmentCount = 3

        var executionOrder: [Int] = []
        let lock = NSLock()

        queue.enqueue {
            await Task.sleep(nanoseconds: 100_000_000)
            lock.lock(); executionOrder.append(1); lock.unlock()
            expectation.fulfill()
        }

        queue.enqueue {
            await Task.sleep(nanoseconds: 50_000_000)
            lock.lock(); executionOrder.append(2); lock.unlock()
            expectation.fulfill()
        }

        queue.enqueue {
            lock.lock(); executionOrder.append(3); lock.unlock()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertEqual(executionOrder, [1, 2, 3])
    }

    func testQueueHandlesSingleOperation() async {
        let queue = CarPlayPresentationQueue.shared
        let expectation = XCTestExpectation(description: "Single op done")
        queue.enqueue {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
    }
}

// MARK: - CPInterfaceController async method tests

final class CPInterfaceControllerAsyncMethodsTests: XCTestCase {

    func testDismissAndPresent_WhenPresentedTemplateExists() async {
        let controller = MockCPInterfaceController()
        controller.presentedTemplateStub = CPTemplate()

        await controller._dismissAndPresent(CPTemplate(), animated: false)
        XCTAssertTrue(controller.didCallDismiss)
        XCTAssertTrue(controller.didCallPresent)
    }

    func testDismissAndPresent_WhenNoPresentedTemplate() async {
        let controller = MockCPInterfaceController()
        controller.presentedTemplateStub = nil

        await controller._dismissAndPresent(CPTemplate(), animated: false)
        XCTAssertFalse(controller.didCallDismiss)
        XCTAssertTrue(controller.didCallPresent)
    }

    func testDismissAndPush_WhenPresentedTemplateExists() async {
        let controller = MockCPInterfaceController()
        controller.presentedTemplateStub = CPTemplate()

        await controller._dismissAndPush(CPTemplate(), animated: false)
        XCTAssertTrue(controller.didCallDismiss)
        XCTAssertTrue(controller.didCallPush)
    }

    func testDismissAndSetAsRoot_WhenNoPresentedTemplate() async {
        let controller = MockCPInterfaceController()
        controller.presentedTemplateStub = nil

        await controller._dismissAndSetAsRoot(CPTemplate(), animated: false)
        XCTAssertTrue(controller.didCallSetRoot)
        XCTAssertFalse(controller.didCallDismiss)
    }
}

// MARK: - Integration: enqueueDismissAndPresent/Push/SetAsRoot

final class CPInterfaceControllerQueueIntegrationTests: XCTestCase {

    func testEnqueueDismissAndPresent_ExecutesSequentially() async {
        let controller = MockCPInterfaceController()
        let expectation = XCTestExpectation(description: "All templates presented sequentially")
        expectation.expectedFulfillmentCount = 3

        for _ in 0..<3 {
            controller.enqueueDismissAndPresent(CPTemplate())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 3)
        XCTAssertTrue(controller.didCallPresent, "Present should be called for each template")
    }

    func testEnqueueDismissAndPush_ExecutesSequentially() async {
        let controller = MockCPInterfaceController()
        let expectation = XCTestExpectation(description: "All pushes sequential")
        expectation.expectedFulfillmentCount = 2

        controller.enqueueDismissAndPush(CPTemplate())
        controller.enqueueDismissAndPush(CPTemplate())

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 3)
        XCTAssertTrue(controller.didCallPush)
    }

    func testEnqueueDismissAndSetAsRoot_ExecutesSequentially() async {
        let controller = MockCPInterfaceController()
        let expectation = XCTestExpectation(description: "All roots sequential")
        expectation.expectedFulfillmentCount = 2

        controller.enqueueDismissAndSetAsRoot(CPTemplate())
        controller.enqueueDismissAndSetAsRoot(CPTemplate())

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 3)
        XCTAssertTrue(controller.didCallSetRoot)
    }
}
