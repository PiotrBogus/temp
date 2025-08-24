import Assets
import CarPlay
import Combine
import ComposableArchitecture
import Dependencies
import IKOCommon

final class CarPlayBuyTicketTemplate: CarPlayTemplate {
    let id = UUID()
    @Bindable private var store: StoreOf<CarPlayBuyTicketReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider

    init(store: StoreOf<CarPlayBuyTicketReducer>) {
        self.store = store
        bindObservers()
    }

    private func bindObservers() {
        ViewStore(store, observe: { $0 })
            .publisher
            .templateState
            .receive(on: DispatchQueue.main)
            .sink(
                receiveValue: { [weak self] in
                    switch $0 {
                    case .willAppear:
                        self?.store.send(.onAppear)
                    case .didAppear:
                        self?.newParkingFormTemplate()
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
                case let .accountsSelection(state):
                    self?.accountSelectionTemplate(state: state)
                case .carSelection:
                    break
                case .parkingTimeSelection:
                    break
                case .zoneSelection:
                    break
                case .none:
                    break
                }
            })
            .store(in: &cancellables)
    }

    private func buyTicketTemplate() {
        let template = CPInformationTemplate(
            title: .empty,
            layout: .leading,
            items: [],
            actions: []
        )
        coordinator.interfaceController?.setRootTemplate(template, animated: true, completion: nil)
    }

    private func loadingTemplate(message: String) {
        let template = CarPlayLoadingTemplateFactory.make(message: message)
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func errorTemplate(errorModel: CarPlayErrorTemplateModel<CarPlayBuyTicketFeatureErrorType>) {
        let template = CarPlayErrorTemplateFactory.make(errorModel: errorModel) { 
//            self?.store.send(.onErrorButtonTap(errorModel.type))
        }
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func newParkingFormTemplate() {
        guard let model = store.data else { return }
        let sections = createParkingFormSections(model: model)
        let list = CPListTemplate(title: resourceProvider.newParkingFormTitleText, sections: sections)
        let nextButton = CPBarButton(title: resourceProvider.nextButtonText) { [weak self] _ in
            self?.store.send(.onNextButtonTap)
        }
        list.trailingNavigationBarButtons = [nextButton]

        model.refreshTemplateHandler = { [weak self] in
            guard let self else { return }
            let sections = self.createParkingFormSections(
                model: model
            )

            list.updateSections(sections)
        }
        coordinator.interfaceController?.dismissAndPush(template: list)
    }

    private func createParkingFormSections(
        model: CarPlayParkingsNewParkingFormModel
    ) -> [CPListSection] {
        let zoneRow = createSectionRow(
            title: model.zoneTitle,
            detail: model.zoneDescription,
            image: Assets.imageNamed(IKOImages.IC_CARPLAY_LOCATION),
            selectionEnabled: model.zoneSelectionEnabled,
            handler: { [weak self] in
                self?.store.send(.onSelectZoneTap)
            }
        )
        let timeRow = createSectionRow(
            title: model.timeTitle,
            detail: model.timeDescription,
            image: Assets.imageNamed(IKOImages.IC_CARPLAY_PARKING),
            selectionEnabled: model.timeSelectionEnabled,
            handler: { [weak self] in
                self?.store.send(.onSelectParkingTimeTap)
            }
        )
        let carRow = createSectionRow(
            title: model.carTitle,
            detail: model.carDescription,
            image: Assets.imageNamed(IKOImages.IC_CARPLAY_CAR),
            selectionEnabled: model.carSelectionEnabled,
            handler: { [weak self] in
                self?.store.send(.onSelectCarTap)
            }
        )
        let accountRow = createSectionRow(
            title: model.accountTitle,
            detail: model.accountDescription,
            image: Assets.imageNamed(IKOImages.IC_CARPLAY_ACCOUNT),
            selectionEnabled: model.accountSelectionEnabled,
            handler: { [weak self] in
                self?.store.send(.onSelectAccountsTap)
            }
        )

        let serviceProviderRow = CPListItem(
            text: resourceProvider.serviceProviderText,
            detailText: nil,
            image: Assets.imageNamed(
                IKOImages.IC_CARPLAY_MOBILET
            )
        )
        serviceProviderRow.handler = { _, completion in
            completion()
        }

        return [CPListSection(items: [zoneRow, timeRow, carRow, accountRow, serviceProviderRow])]
    }

    private func createSectionRow(
        title: String,
        detail: String,
        image: UIImage?,
        selectionEnabled: Bool,
        handler: @escaping () -> Void
    ) -> CPListItem {
        let row = CPListItem(text: title, detailText: detail, image: image)
        if selectionEnabled {
            row.accessoryType = .disclosureIndicator
            row.handler = { _, completion in
                handler()
                completion()
            }
        } else {
            row.handler = { _, completion in
                completion()
            }
        }
        return row
    }

    private func accountSelectionTemplate(state: CarPlayAccountSelectionReducer.State) {
        let store = Store(
            initialState: state,
            reducer: {
                CarPlayAccountSelectionReducer()
            }
        )
        coordinator.save(CarPlayAccountSelectionTemplate(store: store))
    }
}
