import CarPlay
import Combine
import Dependencies
import DependenciesMacros

@DependencyClient
struct CarPlayCoordinatorKey: DependencyKey {
    static let liveValue = CarPlayCoordinator()
}

extension DependencyValues {
    var carPlayCoordinator: CarPlayCoordinator {
        get { self[CarPlayCoordinatorKey.self] }
        set { self[CarPlayCoordinatorKey.self] = newValue }
    }
}

final class CarPlayCoordinator: NSObject {
    private(set) var interfaceController: CPInterfaceController?
    private(set) var childTemplate: [any CarPlayTemplate] = []
    private(set) var didPop = PassthroughSubject<CPTemplate, Never>()

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
