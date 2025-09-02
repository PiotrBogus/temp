import CarPlay
import Combine
import ComposableArchitecture
import Dependencies
import UIComponents

final class CarPlayLastUsedParkingDetailsTemplate: CarPlayTemplate {
    @Bindable private var store: StoreOf<CarPlayLastUsedParkingDetailsReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider
    private var mainTemplate: CPInformationTemplate?

    init(store: StoreOf<CarPlayLastUsedParkingDetailsReducer>) {
        self.store = store
        bindObservers()
    }

    private func bindObservers() {
        ViewStore(store, observe: { $0.templateState })
            .publisher
            .sink(receiveValue: { [weak self] in
                switch $0 {
                case .didAppear:
                    self?.lastParkingDetailsTemplate()
                case .loading:
                    self?.loadingSplashTemplate()
                case let .error(model):
                    self?.errorTemplate(errorModel: model)
                }
            })
            .store(in: &cancellables)

        ViewStore(store, observe: { $0.destination })
            .publisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] destination in
                switch destination {
                case let .buyTicket(state):
                    self?.buyTicketTemplate(state: state)
                default:
                    break
                }
            })
            .store(in: &cancellables)

        coordinator.didPop
            .sink { [weak self] _ in
                guard let self,
                      let mainTemplate = self.mainTemplate,
                      !coordinator.contains(template: mainTemplate) else { return }
                self.coordinator.remove(self)
                self.mainTemplate = nil
            }
            .store(in: &cancellables)
    }

        func lastParkingDetailsTemplate() {
            let locationRow = CPInformationItem(
                title: store.model.locationTitle,
                detail: store.model.locationDescription
            )
            let durationRow = CPInformationItem(
                title: store.model.durationTitle,
                detail: store.model.durationDescription
            )
            let carRow = CPInformationItem(
                title: store.model.carTitle,
                detail: store.model.carDescription
            )
            let parkingStartTimeRow = CPInformationItem(
                title: store.model.parkingStartTimeTitle,
                detail: store.model.parkingStartTimeDescription
            )
            let parkingEndTimeRow = CPInformationItem(
                title: store.model.parkingEndTimeTitle,
                detail: store.model.parkingEndTimeDescription
            )
            let repeatButton = CPTextButton(
                title: resourceProvider.lastParkingsTicketDetailsRepeatText,
                textStyle: .cancel
            ) { [weak self] _ in
                self?.store.send(.onConfirm)
            }
            mainTemplate = CPInformationTemplate(
                title: resourceProvider.lastParkingsTicketDetailsTitleText,
                layout: .leading,
                items: [locationRow, durationRow, carRow, parkingStartTimeRow, parkingEndTimeRow],
                actions: [repeatButton]
            )
            coordinator.interfaceController?.dismissAndPush(template: mainTemplate!)
    }

    private func buyTicketTemplate(state: CarPlayBuyTicketReducer.State) {
        let store = Store(
            initialState: state,
            reducer: {
                CarPlayBuyTicketReducer()
            }
        )
        coordinator.append(CarPlayBuyTicketTemplate(store: store))
    }

    private func loadingSplashTemplate() {
        let template = CarPlayLoadingTemplateFactory.make(message: resourceProvider.lastParkingTicketRepeatProcessingText)
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func errorTemplate(errorModel: CarPlayErrorTemplateModel<CarPlayLastUsedParkingDetailsErrorType>) {
        let template = CarPlayErrorTemplateFactory.make(errorModel: errorModel) { [weak self] in
            self?.store.send(.onTryAgain)
        }
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }
}
