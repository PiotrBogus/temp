import CarPlay
import Combine
import ComposableArchitecture
import Dependencies
import UIComponents

final class CarPlayActiveTicketTemplate: CarPlayTemplate {
    @Bindable private var store: StoreOf<CarPlayActiveTicketReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider
    private var mainTemplate: CPPointOfInterestTemplate?
    private var activeParkingTimer: Timer?
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
            .sink(receiveValue: { [weak self] in
                switch $0 {
                case .didAppear:
                    self?.activeTicketTemplate()
                case .stopTicket:
                    self?.stopTicketSplashTemplate()
                case let .error(model):
                    self?.errorTemplate(errorModel: model)
                case .entryPoint:
                    self?.entryPointTemplate()
                }
            })
            .store(in: &cancellables)
    }

    private func activeTicketTemplate() {
        mainTemplate = activeParkingOverview(location: store.location)
        guard let template = mainTemplate else { return }

        if let activeParkingTimer = activeParkingTimer {
            activeParkingTimer.invalidate()
        }

        activeParkingTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            let pointOfInterest = CPPointOfInterest(
                location: store.location,
                title: store.ticket.remainingTime,
                subtitle: store.ticket.remainingTimeLabel,
                summary: nil,
                detailTitle: store.ticket.title,
                detailSubtitle: store.ticket.remainingTimeLabel,
                detailSummary: store.ticket.remainingTime,
                pinImage: nil
            )
            template.setPointsOfInterest([pointOfInterest], selectedIndex: NSNotFound)
            if store.ticket.timeIsUp() {
                self.activeParkingTimer?.invalidate()
                self.store.send(.onTicketExpired)
                return
            }
        }

        coordinator.interfaceController?.dismissAndSetAsRoot(template: template)
    }

    private func activeParkingOverview(
        location: MKMapItem?
    ) -> CPPointOfInterestTemplate? {
        guard let location = location else { return nil }
        let pointOfInterest = CPPointOfInterest(
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
        let activeParkingTemplate = CPPointOfInterestTemplate(
            title: store.ticket.title,
            pointsOfInterest: [pointOfInterest],
            selectedIndex: NSNotFound
        )
        activeParkingTemplate.trailingNavigationBarButtons = [stopButton]
        activeParkingTemplate.pointOfInterestDelegate = poiDelegate
        return activeParkingTemplate
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
