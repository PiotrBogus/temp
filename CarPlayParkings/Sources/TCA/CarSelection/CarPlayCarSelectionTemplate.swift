import CarPlay
import Combine
import ComposableArchitecture
import Dependencies

final class CarPlayCarSelectionTemplate: CarPlayTemplate {
    @Bindable private var store: StoreOf<CarPlayCarSelectionReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider
    private var mainTemplate: CPTemplate?

    init(store: StoreOf<CarPlayCarSelectionReducer>) {
        self.store = store
        bindObservers()
    }

    private func bindObservers() {
        ViewStore(store, observe: { $0 })
            .publisher
            .templateState
            .sink(receiveValue: { [weak self] in
                switch $0 {
                case .didAppear:
                    self?.selectCarTemplate()
                }
            })
            .store(in: &cancellables)

        coordinator.didPop
            .sink { [weak self] _ in
                guard let self,
                      let mainTemplate = self.mainTemplate,
                      !coordinator.contains(template: mainTemplate) else { return }
                self.mainTemplate = nil
                self.store.send(.didPop)
                self.coordinator.remove(self)
            }
            .store(in: &cancellables)
    }

    private func selectCarTemplate() {
        let items = store.cars.map { [weak self] car in
            let listItem = CPListItem(text: car.name, detailText: car.plate)
            listItem.handler = { _, completion in
                defer { completion() }
                guard let self else { return }
                self.store.send(.onCarSelection(car))
                self.coordinator.remove(self)
            }
            return listItem
        }
        mainTemplate = CPListTemplate(title: resourceProvider.selectCarTitleText, sections: [CPListSection(items: items)])
        coordinator.interfaceController?.dismissAndPush(template: mainTemplate!)
    }
}
