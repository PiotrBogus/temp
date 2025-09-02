import CarPlay
import Combine
import ComposableArchitecture
import Dependencies

final class CarPlayAccountSelectionTemplate: CarPlayTemplate {
    @Bindable private var store: StoreOf<CarPlayAccountSelectionReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider
    private var mainTemplate: CPTemplate?

    init(store: StoreOf<CarPlayAccountSelectionReducer>) {
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
                    self?.selectAccountTemplate()
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

    private func selectAccountTemplate() {
        let items = store.accounts.compactMap { account in
            let listItem = CPListItem(text: account.name, detailText: account.digest)
            listItem.handler = { [weak self] _, completion in
                defer { completion() }
                guard let self else { return }
                self.store.send(.onAccountSelection(account))
                self.coordinator.remove(self)
            }
            return listItem
        }
        mainTemplate = CPListTemplate(title: resourceProvider.selectAccountTitleText, sections: [CPListSection(items: items)])
        coordinator.interfaceController?.dismissAndPush(template: mainTemplate!)
    }
}
