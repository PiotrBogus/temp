import CarPlay
import Combine
import Foundation

public protocol CarPlayCoordinating: AnyObject, Sendable {
    var interfaceController: CPInterfaceController? { get }
    var didPop: PassthroughSubject<CPTemplate, Never> { get }

    func save(_ interfaceController: CPInterfaceController)
    func register(_ template: any CarPlayTemplate, cpTemplate: CPTemplate?)
    func removeAll()
    func cpTemplate(for template: any CarPlayTemplate) -> CPTemplate?
    func carPlayTemplate(for cpTemplate: CPTemplate) -> (any CarPlayTemplate)?
    func contains(template: CPTemplate) -> Bool
}



import CarPlay
import Combine
import Dependencies
import DependenciesMacros

struct CarPlayCoordinatorKey: DependencyKey {
    static let liveValue: any CarPlayCoordinating = CarPlayCoordinator()
}

extension DependencyValues {
    var carPlayCoordinator: any CarPlayCoordinating {
        get { self[CarPlayCoordinatorKey.self] }
        set { self[CarPlayCoordinatorKey.self] = newValue }
    }
}

final class CarPlayCoordinator: NSObject, CarPlayCoordinating, @unchecked Sendable {
    private(set) var interfaceController: CPInterfaceController?
    private(set) var didPop = PassthroughSubject<CPTemplate, Never>()

    private var registry: [String: (any CarPlayTemplate, CPTemplate?)] = [:]

    func save(_ interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        self.interfaceController?.delegate = self
    }

    func register(_ template: any CarPlayTemplate, cpTemplate: CPTemplate?) {
        registry[template.id] = (template, cpTemplate)
    }

    func remove(_ template: any CarPlayTemplate) {
        registry.removeValue(forKey: template.id)
    }

    func removeAll() {
        registry.removeAll()
    }

    func cpTemplate(for template: any CarPlayTemplate) -> CPTemplate? {
        registry[template.id]?.1
    }

    func carPlayTemplate(for template: CPTemplate) -> (any CarPlayTemplate)? {
        registry.values.first(where: { $0.1 == template })?.0
    }

    func contains(template: CPTemplate) -> Bool {
        interfaceController?.templates.contains(where: { $0 === template }) ?? false
    }
}

extension CarPlayCoordinator: CPInterfaceControllerDelegate {
    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        didPop.send(aTemplate)

        if let carPlayTemplate = carPlayTemplate(for: aTemplate),
            !contains(template: aTemplate) {
            carPlayTemplate.didDisappear(template: aTemplate)
            remove(carPlayTemplate)
        }
    }
}
