import CarPlay
import Combine
import ComposableArchitecture
import Dependencies

final class CarPlayZoneSelectionTemplate: CarPlayTemplate {
    @Bindable private var store: StoreOf<CarPlayZoneSelectionReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider
    private var mainTemplate: CPTemplate?

    init(store: StoreOf<CarPlayZoneSelectionReducer>) {
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
                    self?.selectZoneTemplate()
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

    private func selectZoneTemplate() {
        guard let city = store.city else { return }
        let subareas = city.tarrifs.flatMap { tariff in
            tariff.subareas.filter { !$0.timeOptions.isEmpty }
        }
        let zones = subareas.map { [weak self] subarea in
            let item = CPListItem(text: city.name, detailText: subarea.name)
            item.handler = { _, completion in
                defer { completion() }
                guard let self else { return }
                self.store.send(.onZoneSelection(subarea))
                self.coordinator.remove(self)
            }
            return item
        }
        mainTemplate = CPListTemplate(title: resourceProvider.selectParkingZoneText, sections: [CPListSection(items: zones)])
        coordinator.interfaceController?.dismissAndPush(template: mainTemplate!)
    }
}
