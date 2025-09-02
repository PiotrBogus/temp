
public protocol CarPlayCoordinating: AnyObject, Sendable {
    var interfaceController: CPInterfaceController? { get }
    var didPop: PassthroughSubject<CPTemplate, Never> { get }

    func save(_ interfaceController: CPInterfaceController)
    func append(_ child: any CarPlayTemplate)
    func remove(_ child: any CarPlayTemplate)
    func removeAllChilds()
    func contains(template: CPTemplate) -> Bool
}




import Foundation
import CarPlay
import Combine

final class CarPlayCoordinator: NSObject, CarPlayCoordinating {
    private(set) var interfaceController: CPInterfaceController?
    private(set) var childTemplate: [any CarPlayTemplate] = []
    let didPop = PassthroughSubject<CPTemplate, Never>()

    func save(_ interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        self.interfaceController?.delegate = self
    }

    func append(_ child: any CarPlayTemplate) {
        childTemplate.append(child)
    }

    func remove(_ child: any CarPlayTemplate) {
        childTemplate.removeAll(where: { $0.id == child.id })
    }

    func removeAllChilds() {
        childTemplate.removeAll()
    }

    func contains(template: CPTemplate) -> Bool {
        interfaceController?.templates.contains(where: { $0 === template }) ?? false
    }
}

extension CarPlayCoordinator: CPInterfaceControllerDelegate {
    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        didPop.send(aTemplate)
    }
}






import CarPlay
import Combine

final class CarPlayCoordinatorMock: CarPlayCoordinating {
    var interfaceController: CPInterfaceController? = CarPlayInterfaceControllerMock()
    let didPop = PassthroughSubject<CPTemplate, Never>()

    private(set) var appended: [any CarPlayTemplate] = []
    private(set) var removed: [any CarPlayTemplate] = []
    private(set) var removedAllCalled = false
    var containsTemplates: Set<CPTemplate> = []

    func save(_ interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
    }

    func append(_ child: any CarPlayTemplate) {
        appended.append(child)
    }

    func remove(_ child: any CarPlayTemplate) {
        removed.append(child)
    }

    func removeAllChilds() {
        removedAllCalled = true
    }

    func contains(template: CPTemplate) -> Bool {
        containsTemplates.contains { $0 === template }
    }
}
