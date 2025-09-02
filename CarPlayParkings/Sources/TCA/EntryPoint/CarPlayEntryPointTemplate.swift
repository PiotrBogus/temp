import CarPlay
import Combine
import ComposableArchitecture
import Dependencies
import IKOCommon

final class CarPlayEntryPointTemplate: CarPlayTemplate {
    @Bindable private var store: StoreOf<CarPlayEntryPointReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator

    init(store: StoreOf<CarPlayEntryPointReducer>) {
        self.store = store
        bindObservers()
    }

    private func bindObservers() {
        ViewStore(store, observe: { $0 })
            .publisher
            .templateState
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                switch $0 {
                case .willAppear:
                    self?.emptyTemplate()
                    self?.store.send(.onAppear)
                case let .loading(message):
                    self?.loadingTemplate(message: message)
                case let .error(errorModel):
                    self?.errorTemplate(errorModel: errorModel)
                }
            })
            .store(in: &cancellables)

        ViewStore(store, observe: { $0 })
            .publisher
            .destination
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] destination in
                switch destination {
                case let .inactiveTicket(state):
                    self?.inactiveTicketTemplate(state: state)
                case let .activeTicket(state):
                    self?.activeTicketTemplate(state: state)
                case .none:
                    break
                }
            })
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(parkingListNeedsRefresh),
            name: Notification.Name(rawValue: kIKOParkingPlacesListRefresh),
            object: nil
        )
    }

    private func emptyTemplate() {
        let template = CPInformationTemplate(
            title: .empty,
            layout: .leading,
            items: [],
            actions: []
        )
        coordinator.interfaceController?.dismissAndSetAsRoot(template: template)
    }

    private func loadingTemplate(message: String) {
        let template = CarPlayLoadingTemplateFactory.make(message: message)
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func errorTemplate(errorModel: CarPlayErrorTemplateModel<CarPlayEntryPointFeatureErrorType>) {
        let template = CarPlayErrorTemplateFactory.make(errorModel: errorModel) { [weak self] in
            self?.store.send(.onErrorButtonTap(errorModel.type))
        }
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func inactiveTicketTemplate(state: CarPlayInactiveTicketReducer.State) {
        let store = Store(
            initialState: state,
            reducer: {
                CarPlayInactiveTicketReducer()
            }
        )
        coordinator.append(CarPlayInactiveTicketTemplate(store: store))
    }

    private func activeTicketTemplate(state: CarPlayActiveTicketReducer.State) {
        let store = Store(
            initialState: state,
            reducer: {
                CarPlayActiveTicketReducer()
            }
        )
        coordinator.append(CarPlayActiveTicketTemplate(store: store))
    }

    @objc private func parkingListNeedsRefresh() {
        store.send(.refresh)
    }
}
