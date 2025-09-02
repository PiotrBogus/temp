import CarPlay
import Combine
import ComposableArchitecture
import Dependencies
import UIComponents

final class CarPlayConfirmParkingTemplate: CarPlayTemplate {
    @Bindable private var store: StoreOf<CarPlayConfirmParkingReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider
    private var mainTemplate: CPInformationTemplate?

    init(store: StoreOf<CarPlayConfirmParkingReducer>) {
        self.store = store
        bindObservers()
    }

    private func bindObservers() {
        ViewStore(store, observe: { $0.templateState })
            .publisher
            .sink(receiveValue: { [weak self] in
                switch $0 {
                case .didAppear:
                    self?.confirmParkingTemplate()
                case let .error(model):
                    self?.errorTemplate(errorModel: model)
                case .loading:
                    self?.splashTemplate()
                case .entryPoint:
                    self?.entryPointTemplate()
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

    private func confirmParkingTemplate() {
        let zoneRow = CPInformationItem(title: store.model.zoneTitle, detail: store.model.zoneTitle)
        let typeAndPriceRow = CPInformationItem(
            title: resourceProvider.confirmationParkingTimeTypeText,
            detail: resourceProvider.parkingTimeWithPriceText(
                time: store.preauthResponse.boughtTime(),
                price: "\(store.preauthResponse.price)" + .space + IKOMoney.defaultCurrency()
            )
        )
        let carRow = CPInformationItem(
            title: resourceProvider.confirmationParkingCarText,
            detail: store.preauthResponse.plate
        )
        let accountRow = CPInformationItem(
            title: resourceProvider.confirmationParkingAccountText,
            detail: store.model.accountDescription
        )
        let confirmButton = CPTextButton(
            title: resourceProvider.confirmationParkingAcceptText,
            textStyle: .confirm
        ) { [weak self] _ in
            self?.store.send(.onConfirm)
        }

        mainTemplate = CPInformationTemplate(
            title: resourceProvider.confirmationParkingTitleText,
            layout: .leading,
            items: [zoneRow, typeAndPriceRow, carRow, accountRow],
            actions: [confirmButton]
        )
        coordinator.interfaceController?.dismissAndPush(template: mainTemplate!)
    }

    private func errorTemplate(errorModel: CarPlayErrorTemplateModel<CarPlayConfirmParkingErrorType>) {
        let template = CarPlayErrorTemplateFactory.make(errorModel: errorModel) { [weak self] in
            self?.store.send(.onTryAgain)
        }
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func splashTemplate() {
        let template = CPAlertTemplate(titleVariants: [resourceProvider.authNewParkingProcessingText], actions: [])
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func entryPointTemplate() {
        self.coordinator.removeAllChilds()
        let store = Store(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: {
                CarPlayEntryPointReducer()
            }
        )
        coordinator.append(CarPlayEntryPointTemplate(store: store))
    }
}
