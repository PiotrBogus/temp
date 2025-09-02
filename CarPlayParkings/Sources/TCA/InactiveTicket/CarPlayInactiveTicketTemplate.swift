import Assets
import CarPlay
import Combine
import ComposableArchitecture
import Dependencies

final class CarPlayInactiveTicketTemplate: CarPlayTemplate {
    @Bindable private var store: StoreOf<CarPlayInactiveTicketReducer>
    private var cancellables = Set<AnyCancellable>()
    @Dependency(\.carPlayCoordinator) private var coordinator
    @Dependency(\.carPlayResourceProvider) private var resourceProvider
    private let poiDelegate: CarPlayPOIDelegate

    init(
        store: StoreOf<CarPlayInactiveTicketReducer>,
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
                case .willAppear:
                    self?.store.send(.onAppear)
                case let .loading(message):
                    self?.loadingTemplate(message: message)
                case let .error(errorModel):
                    self?.errorTemplate(errorModel: errorModel)
                case let .inactiveTicket(model):
                    self?.inactiveParkingTicketTemplate(model: model)
                }
            })
            .store(in: &cancellables)

        ViewStore(store, observe: { $0.destination })
            .publisher
            .sink(receiveValue: { [weak self] destination in
                switch destination {
                case let .buyTicket(state):
                    self?.resetDestination()
                    self?.buyTicketTemplate(state: state)
                case let .lastUsedParkingDetails(state):
                    self?.resetDestination()
                    self?.lastUsedParkingDetailsTemplate(state: state)
                case .none:
                    break
                }
            })
            .store(in: &cancellables)

        poiDelegate.$selectedPOI
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                guard let poi else { return }
                self?.store.send(.didSelectPOI(poi))
            }
            .store(in: &cancellables)
    }

    private func loadingTemplate(message: String) {
        let template = CarPlayLoadingTemplateFactory.make(message: message)
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func errorTemplate(errorModel: CarPlayErrorTemplateModel<CarPlayInactiveTicketFeatureErrorType>) {
        let template = CarPlayErrorTemplateFactory.make(errorModel: errorModel) { [weak self] in
            self?.store.send(.onErrorButtonTap(errorModel.type))
        }
        coordinator.interfaceController?.dismissAndPresent(template: template)
    }

    private func inactiveParkingTicketTemplate(model: CarPlayInactiveParkingTicketTemplateModel) {
        var templates: [CPTemplate] = []
        let citiesTemplate = createCitiesTab(
            cities: model.cities,
            carLocation: model.carLocation
        )
        templates.append(citiesTemplate)
        let parkingsTemplate = createLastUsedParkingsTab(lastUsedParkings: model.lastUsedParkings)
        templates.append(parkingsTemplate)
        let tabBarTemplate = CPTabBarTemplate(templates: templates)
        coordinator.interfaceController?.dismissAndSetAsRoot(template: tabBarTemplate)
    }

    private func createCitiesTab(
        cities: [CarPlayParkingsCity],
        carLocation: MKMapItem,
    ) -> CPPointOfInterestTemplate {
        let model = CarPlayParkingsSelectCityModel(cities: cities, resourceProvider: resourceProvider)
        var pois = model.cities.map { city in
            CPPointOfInterest(
                location: city.location,
                title: city.title,
                subtitle: city.subtitle,
                summary: nil,
                detailTitle: nil,
                detailSubtitle: nil,
                detailSummary: nil,
                pinImage: nil
            )
        }
        if pois.isEmpty {
            pois.append(CPPointOfInterest(
                location: carLocation,
                title: resourceProvider.noActiveParkingSelectCityEmptyText,
                subtitle: nil,
                summary: nil,
                detailTitle: .empty,
                detailSubtitle: nil,
                detailSummary: resourceProvider.noActiveParkingSelectCityEmptyText,
                pinImage: nil
            ))
        }
        let poiTemplate = CPPointOfInterestTemplate(title: model.title, pointsOfInterest: pois, selectedIndex: NSNotFound)
        poiTemplate.tabTitle = resourceProvider.newParkingTabTitleText
        poiTemplate.tabImage = Assets.imageNamed(IKOImages.IC_CARPLAY_PARKING)
        poiTemplate.pointOfInterestDelegate = poiDelegate
        return poiTemplate
    }

    private func createLastUsedParkingsTab(lastUsedParkings: [CarPlayParkingsTicketListItem]) -> CPListTemplate {
        let tickets = lastUsedParkings.map { ticket in
            let model = CarPlayParkingsRecentTicketModel(ticket: ticket, resourceProvider: resourceProvider)
            let item = CPListItem(text: model.title, detailText: model.description)
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, completion in
                defer { completion() }
                self?.store.send(.onLastUsedParkingSelection(ticket))
            }
            return item
        }
        let parkingsTemplate = CPListTemplate(title: resourceProvider.lastParkingsTitleText, sections: [CPListSection(items: tickets)])
        parkingsTemplate.tabTitle = resourceProvider.historyTabTitleText
        parkingsTemplate.tabImage = Assets.imageNamed(IKOImages.IC_CARPLAY_HISTORY)
        return parkingsTemplate
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

    private func lastUsedParkingDetailsTemplate(state: CarPlayLastUsedParkingDetailsReducer.State) {
        let store = Store(
            initialState: state,
            reducer: {
                CarPlayLastUsedParkingDetailsReducer()
            }
        )
        coordinator.append(CarPlayLastUsedParkingDetailsTemplate(store: store))
    }

    private func resetDestination() {
        store.send(.resetDestination)
    }
}
