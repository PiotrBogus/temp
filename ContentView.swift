import CarPlay
import Combine
import ComposableArchitecture
import UIComponents

final class CarPlayActiveTicketTemplate: CarPlayTemplate {
    @Bindable private var store: StoreOf<CarPlayActiveTicketReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider
    private var mainTemplate: CPPointOfInterestTemplate?
    private let poiDelegate: CarPlayPOIDelegate

    init(
        store: StoreOf<CarPlayActiveTicketReducer>,
        poiDelegate: CarPlayPOIDelegate = .init()
    ) {
        self.store = store
        self.poiDelegate = poiDelegate
        bindObservers()
    }

    private func bindObservers() {
        ViewStore(store, observe: { $0.templateState })
            .publisher
            .sink(receiveValue: { [weak self] state in
                guard let self else { return }
                switch state {
                case .didAppear:
                    self.activeTicketTemplate()
                case .stopTicket:
                    self.stopTicketSplashTemplate()
                case let .error(model):
                    self.errorTemplate(errorModel: model)
                case .entryPoint:
                    self.entryPointTemplate()
                }
            })
            .store(in: &cancellables)

        // Timer updates: aktualizacja remainingTime w template
        ViewStore(store, observe: \.ticket.remainingTime)
            .publisher
            .sink { [weak self] remainingTime in
                guard let self,
                      let template = self.mainTemplate,
                      let location = self.store.location else { return }

                let poi = CPPointOfInterest(
                    location: location,
                    title: remainingTime,
                    subtitle: self.store.ticket.remainingTimeLabel,
                    summary: nil,
                    detailTitle: self.store.ticket.title,
                    detailSubtitle: self.store.ticket.remainingTimeLabel,
                    detailSummary: remainingTime,
                    pinImage: nil
                )
                template.setPointsOfInterest([poi], selectedIndex: NSNotFound)
            }
            .store(in: &cancellables)
    }

    private func activeTicketTemplate() {
        guard let location = store.location else { return }

        let poi = CPPointOfInterest(
            location: location,
            title: store.ticket.remainingTime,
            subtitle: store.ticket.remainingTimeLabel,
            summary: nil,
            detailTitle: store.ticket.title,
            detailSubtitle: store.ticket.remainingTimeLabel,
            detailSummary: store.ticket.remainingTime,
            pinImage: nil
        )

        let stopButton = CPBarButton(title: resourceProvider.activeTicketOverviewStopButtonText) { [weak self] _ in
            self?.store.send(.onStopTicket)
        }

        let template = CPPointOfInterestTemplate(
            title: store.ticket.title,
            pointsOfInterest: [poi],
            selectedIndex: NSNotFound
        )
        template.trailingNavigationBarButtons = [stopButton]
        template.pointOfInterestDelegate = poiDelegate

        self.mainTemplate = template
        coordinator.interfaceController?.dismissAndSetAsRoot(template: template)
    }

    private func stopTicketSplashTemplate() {
        let template = CarPlayLoadingTemplateFactory.make(message: resourceProvider.processingStopActiveParkingText)
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func errorTemplate(errorModel: CarPlayErrorTemplateModel<CarPlayActiveTicketErrorType>) {
        let template = CarPlayErrorTemplateFactory.make(errorModel: errorModel) { [weak self] in
            self?.store.send(.onTryAgain)
        }
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func entryPointTemplate() {
        coordinator.removeAllChilds()
        let store = Store(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }
        )
        coordinator.append(CarPlayEntryPointTemplate(store: store))
    }
}
