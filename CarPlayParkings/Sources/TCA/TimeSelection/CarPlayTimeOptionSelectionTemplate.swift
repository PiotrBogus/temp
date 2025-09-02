import CarPlay
import Combine
import ComposableArchitecture
import Dependencies

final class CarPlayTimeOptionSelectionTemplate: CarPlayTemplate {
    @Bindable private var store: StoreOf<CarPlayTimeOptionSelectionReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider
    private let completion: (CarPlayParkingsTariffTimeOption?) -> Void
    private var mainTemplate: CPListTemplate?

    init(store: StoreOf<CarPlayTimeOptionSelectionReducer>, completion: @escaping (CarPlayParkingsTariffTimeOption?) -> Void) {
        self.store = store
        self.completion = completion
        bindObservers()
    }

    private func bindObservers() {
        ViewStore(store, observe: { $0.templateState })
            .publisher
            .sink(receiveValue: { [weak self] in
                switch $0 {
                case .didAppear:
                    self?.selectTimeOptionTemplate()
                case let .fixedTimeOptionSelection(timeOptions):
                    self?.selectFixedTimeOptionTemplate(timeOptions: timeOptions)
                }
            })
            .store(in: &cancellables)

        coordinator.didPop
            .sink { [weak self] _ in
                guard let self,
                      let mainTemplate = self.mainTemplate,
                      !coordinator.contains(template: mainTemplate) else { return }
                self.mainTemplate = nil
                self.completion(nil)
                self.coordinator.remove(self)
            }
            .store(in: &cancellables)
    }

    private func selectTimeOptionTemplate() {
        var items: [CPListItem] = []
        if let startStopOption = store.timeOptions.first(where: { $0 == .startStop }) {
            let startStopRow = CPListItem(text: resourceProvider.startStopRowTitleText, detailText: resourceProvider.startStopRowDescriptionText)
            startStopRow.handler = { [weak self] _, completion in
                defer { completion() }
                guard let self else { return }
                self.completion(startStopOption)
                self.coordinator.remove(self)
            }
            items.append(startStopRow)
        }
        let fixedTimeOptions = store.timeOptions.filter { option in
            option != .startStop
        }
        if !fixedTimeOptions.isEmpty {
            let title = fixedTimeOptions.hasOneElement
            ? fixedTimeOptions.first?.toDescription(resourceProvider: resourceProvider)
            : resourceProvider.selectParkingTimeFixedTimeTitleText

            let detailText = fixedTimeOptions.hasOneElement
            ? String.empty
            : resourceProvider.selectParkingTimeFixedTimeDescrText

            let fixedTimeRow = CPListItem(
                text: title,
                detailText: detailText
            )
            fixedTimeRow.handler = { [weak self] _, completion in
                defer { completion() }
                self?.store.send(.onFixedTimeOptionSelection(fixedTimeOptions))
            }
            items.append(fixedTimeRow)
        }
         mainTemplate = CPListTemplate(title: resourceProvider.selectParkingTimeTypeText, sections: [CPListSection(items: items)])
        coordinator.interfaceController?.dismissAndPush(template: mainTemplate!)
    }

    private func selectFixedTimeOptionTemplate(timeOptions: [CarPlayParkingsTariffTimeOption]) {
        let items: [CPListItem] = timeOptions.compactMap { [weak self] option in
            guard let self else { return nil }
            let listItem = CPListItem(text: option.toDescription(resourceProvider: self.resourceProvider), detailText: .empty)
            listItem.handler = { _, completion in
                defer { completion() }
                self.completion(option)
                self.coordinator.remove(self)
            }
            return listItem
        }
        let template = CPListTemplate(title: resourceProvider.selectFixedParkingTimeTypeText, sections: [CPListSection(items: items)])
        coordinator.interfaceController?.dismissAndPush(template: template)
    }
}
