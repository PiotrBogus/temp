import CarPlay
import XCTest

final class FlexibleMockCPInterfaceController: CPInterfaceController {
    var presentedTemplateInternal: CPTemplate? = nil
    override var presentedTemplate: CPTemplate? { presentedTemplateInternal }

    var presentedTemplates: [String] = []
    var pushedTemplates: [String] = []
    var rootTemplates: [String] = []
    var dismissedTemplates: [String] = []

    var presentExpectation: XCTestExpectation?
    var pushExpectation: XCTestExpectation?
    var rootExpectation: XCTestExpectation?
    var dismissExpectation: XCTestExpectation?

    override func presentTemplate(_ template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        presentedTemplates.append(template.titleVariants.first ?? "unknown")
        presentedTemplateInternal = template
        completion?(true, nil)
        presentExpectation?.fulfill()
    }

    override func pushTemplate(_ template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        pushedTemplates.append(template.titleVariants.first ?? "unknown")
        completion?(true, nil)
        pushExpectation?.fulfill()
    }

    override func setRootTemplate(_ template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        rootTemplates.append(template.titleVariants.first ?? "unknown")
        presentedTemplateInternal = template
        completion?(true, nil)
        rootExpectation?.fulfill()
    }

    override func dismissTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
        if let current = presentedTemplateInternal {
            dismissedTemplates.append(current.titleVariants.first ?? "unknown")
        }
        presentedTemplateInternal = nil
        completion?(true, nil)
        dismissExpectation?.fulfill()
    }
}




@MainActor
final class CarPlayPresentationQueueTests: XCTestCase {

    func testEnqueueDismissAndPresentWhenNoTemplate() {
        let controller = FlexibleMockCPInterfaceController()
        let template = CPAlertTemplate(titleVariants: ["First"], actions: [])

        let presentExp = expectation(description: "Present template")
        controller.presentExpectation = presentExp

        controller.enqueueDismissAndPresent(template: template)

        wait(for: [presentExp], timeout: 1.0)
        XCTAssertEqual(controller.presentedTemplates, ["First"])
    }

    func testEnqueueDismissAndPresentWhenTemplateAlreadyPresented() {
        let controller = FlexibleMockCPInterfaceController()
        let initialTemplate = CPAlertTemplate(titleVariants: ["Initial"], actions: [])
        let newTemplate = CPAlertTemplate(titleVariants: ["New"], actions: [])

        // Ustawiamy początkowy template
        controller.presentedTemplateInternal = initialTemplate

        // Oczekiwania na dismiss i present
        let dismissExp = expectation(description: "Dismiss old template")
        let presentExp = expectation(description: "Present new template")
        controller.dismissExpectation = dismissExp
        controller.presentExpectation = presentExp

        controller.enqueueDismissAndPresent(template: newTemplate)

        wait(for: [dismissExp, presentExp], timeout: 1.0)

        XCTAssertEqual(controller.dismissedTemplates, ["Initial"])
        XCTAssertEqual(controller.presentedTemplates, ["New"])
        XCTAssertEqual(controller.presentedTemplate?.titleVariants.first, "New")
    }

    func testEnqueueDismissAndPushExecutesInOrder() {
        let controller = FlexibleMockCPInterfaceController()
        let template1 = CPAlertTemplate(titleVariants: ["Push1"], actions: [])
        let template2 = CPAlertTemplate(titleVariants: ["Push2"], actions: [])

        let exp1 = expectation(description: "First push")
        let exp2 = expectation(description: "Second push")
        controller.pushExpectation = exp1

        controller.enqueueDismissAndPush(template: template1)

        controller.pushExpectation = exp2
        controller.enqueueDismissAndPush(template: template2)

        wait(for: [exp1, exp2], timeout: 1.0)
        XCTAssertEqual(controller.pushedTemplates, ["Push1", "Push2"])
    }

    func testEnqueueDismissAndSetAsRootExecutesInOrder() {
        let controller = FlexibleMockCPInterfaceController()
        let template1 = CPAlertTemplate(titleVariants: ["Root1"], actions: [])
        let template2 = CPAlertTemplate(titleVariants: ["Root2"], actions: [])

        let exp1 = expectation(description: "First root")
        let exp2 = expectation(description: "Second root")
        controller.rootExpectation = exp1

        controller.enqueueDismissAndSetAsRoot(template: template1)

        controller.rootExpectation = exp2
        controller.enqueueDismissAndSetAsRoot(template: template2)

        wait(for: [exp1, exp2], timeout: 1.0)
        XCTAssertEqual(controller.rootTemplates, ["Root1", "Root2"])
        XCTAssertEqual(controller.presentedTemplate?.titleVariants.first, "Root2")
    }

    func testQueueProcessesMixedOperationsSequentially() {
        let controller = FlexibleMockCPInterfaceController()
        let templateA = CPAlertTemplate(titleVariants: ["A"], actions: [])
        let templateB = CPAlertTemplate(titleVariants: ["B"], actions: [])
        let templateC = CPAlertTemplate(titleVariants: ["C"], actions: [])

        let expA = expectation(description: "A presented")
        let expB = expectation(description: "B pushed")
        let expC = expectation(description: "C root")

        controller.presentExpectation = expA
        controller.pushExpectation = expB
        controller.rootExpectation = expC

        controller.enqueueDismissAndPresent(template: templateA)
        controller.enqueueDismissAndPush(template: templateB)
        controller.enqueueDismissAndSetAsRoot(template: templateC)

        wait(for: [expA, expB, expC], timeout: 1.0)

        XCTAssertEqual(controller.presentedTemplates, ["A"])
        XCTAssertEqual(controller.pushedTemplates, ["B"])
        XCTAssertEqual(controller.rootTemplates, ["C"])
    }
}
