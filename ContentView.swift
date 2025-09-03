final class CarPlayCoordinator: NSObject {
    private(set) var interfaceController: CPInterfaceController?
    private(set) var didPop = PassthroughSubject<CPTemplate, Never>()

    /// Rejestr: CarPlayTemplate.id → (CarPlayTemplate, CPTemplate)
    private var registry: [UUID: (any CarPlayTemplate, CPTemplate)] = [:]

    func save(_ interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        self.interfaceController?.delegate = self
    }

    func register(_ template: any CarPlayTemplate, cpTemplate: CPTemplate) {
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

    func carPlayTemplate(for cpTemplate: CPTemplate) -> (any CarPlayTemplate)? {
        registry.values.first(where: { $0.1 === cpTemplate })?.0
    }

    func contains(cpTemplate: CPTemplate) -> Bool {
        interfaceController?.templates.contains(where: { $0 === cpTemplate }) ?? false
    }

    var allTemplates: [any CarPlayTemplate] {
        registry.values.map(\.0)
    }
}

extension CarPlayCoordinator: CPInterfaceControllerDelegate {
    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        didPop.send(aTemplate)

        if let carPlayTemplate = carPlayTemplate(for: aTemplate) {
            carPlayTemplate.didDisappear(cpTemplate: aTemplate) // 🔔 callback
            remove(carPlayTemplate)
        }
    }
}
