import CarPlay
import Combine
import ComposableArchitecture
import Dependencies

final class CarPlayAccountSelectionTemplate: CarPlayTemplate {
    let id = UUID()
    @Bindable private var store: StoreOf<CarPlayAccountSelectionReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider

    init(store: StoreOf<CarPlayAccountSelectionReducer>,) {
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
    }

    private func selectAccountTemplate() {
        let items = store.accounts.compactMap { account in
            let listItem = CPListItem(text: account.name, detailText: account.digest)
            listItem.handler = { [weak self] item, _ in
                guard let self else { return }
                self.store.send(.onAccountSelection(account))
                self.coordinator.interfaceController?.popTemplate(animated: true, completion: nil)
                self.coordinator.remove(self)
            }
            return listItem
        }
        let template = CPListTemplate(title: resourceProvider.selectAccountTitleText, sections: [CPListSection(items: items)])
        coordinator.interfaceController?.dismissAndPush(template: template)
    }
}
