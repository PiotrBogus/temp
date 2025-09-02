import CarPlay
import ComposableArchitecture
import Dependencies

@Reducer
struct CarPlayBuyTicketReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?
        var subareaHint: String?
        var data: CarPlayParkingsNewParkingFormModel?
        var templateState: TemplateState = .willAppear
    }

    enum TemplateState: Equatable {
        case willAppear
        case didAppear
        case loading(String)
        case error(CarPlayErrorTemplateModel<CarPlayBuyTicketFeatureErrorType>)
        case didChangeData(UUID = UUID())
        case validationError(UUID, [BuyTicketFormValidationError])
        case preauthNewParkingProcessingSplash
    }

    enum Action: Sendable {
        case destination(PresentationAction<Destination.Action>)
        case onAppear
        case didLoadData(CarPlayParkingsNewParkingFormModel)
        case refresh
        case onErrorButtonTap(CarPlayBuyTicketFeatureErrorType)
        case onNextButtonTap
        case onValidationFormError([BuyTicketFormValidationError])
        case onValidationFormSuccess
        case onSelectZoneTap
        case onSelectTimeOptionsTap
        case onSelectAccountsTap
        case onSelectCarTap
        case didLoadAccounts([CarPlayParkingsAccount])
        case didLoadSelectedCity(CarPlayParkingsCity)
        case didLoadCars([CarPlayParkingsCarListItem])
        case didSelectTimeOption(CarPlayParkingsTariffTimeOption?)
        case didPreauthorizeParking(CarPlayParkingsPreauthResponse)
        case error(Error)
    }

    @Reducer(state: .equatable, .sendable, action: .sendable)
    enum Destination: Equatable {
        case zoneSelection(CarPlayZoneSelectionReducer)
        case timeOptionSelection(CarPlayTimeOptionSelectionReducer)
        case accountsSelection(CarPlayAccountSelectionReducer)
        case carSelection(CarPlayCarSelectionReducer)
        case confirmParking(CarPlayConfirmParkingReducer)

        static func == (lhs: CarPlayBuyTicketReducer.Destination, rhs: CarPlayBuyTicketReducer.Destination) -> Bool {
            switch (lhs, rhs) {
            case (.zoneSelection, .zoneSelection),
                (.timeOptionSelection, .timeOptionSelection),
                (.accountsSelection, .accountsSelection),
                (.carSelection, .carSelection):
                return true
            default:
                return false
            }
        }
    }

    @Dependency(\.buyTicketReducerClient) private var reducerClient
    @Dependency(\.carPlayParkingsErrorParser) private var errorParser

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.data == nil {
                    return loadData(subareaHint: state.subareaHint)
                } else {
                    state.templateState = .didAppear
                    return .none
                }
            case let .didLoadData(data):
                state.data = data
                state.templateState = .didAppear
                return .none
            case .onSelectZoneTap:
                return loadSelectedCity()
            case let .didLoadSelectedCity(city):
                state.destination = .zoneSelection(CarPlayZoneSelectionReducer.State(city: city))
                return .none
            case .onSelectTimeOptionsTap:
                let timeOptions = state.data?.selectedSubarea?.timeOptions ?? []
                state.destination = .timeOptionSelection(CarPlayTimeOptionSelectionReducer.State(timeOptions: timeOptions))
                return .none
            case .onSelectAccountsTap:
                return loadAccounts()
            case let .didLoadAccounts(accounts):
                state.destination = .accountsSelection(CarPlayAccountSelectionReducer.State(accounts: accounts))
                return .none
            case .onSelectCarTap:
                return loadCars()
            case let .didLoadCars(cars):
                state.destination = .carSelection(CarPlayCarSelectionReducer.State(cars: cars))
                return .none
            case .onNextButtonTap:
                guard let data = state.data else { return .none }
                return validateForm(model: data)
            case .onValidationFormSuccess:
                guard let data = state.data else { return .none }
                state.templateState = .preauthNewParkingProcessingSplash
                return preauthorizeParking(data: data)
            case let .onValidationFormError(errors):
                state.templateState = .validationError(UUID(), errors)
                return .none
            case .refresh:
                state.templateState = .loading(reducerClient.resourceProvider.loadingSplashText)
                return .none
            case .onErrorButtonTap:
                return .send(.onNextButtonTap)
            case .destination(.presented(.accountsSelection(.delegate(.dismissAccountSelection(let account))))):
                guard let account else {
                    state.destination = nil
                    return .none
                }
                state.data?.selectedAccount = account
                state.data?.refresh()
                state.templateState = .didChangeData()
                state.destination = nil
                return .none
            case .destination(.presented(.zoneSelection(.delegate(.dismissZoneSelection(let zone))))):
                guard let zone else {
                    state.destination = nil
                    return .none
                }
                state.data?.selectedSubarea = zone
                state.data?.refresh()
                state.templateState = .didChangeData()
                state.destination = nil
                return .none
            case .destination(.presented(.carSelection(.delegate(.dismissCarSelection(let car))))):
                guard let car else {
                    state.destination = nil
                    return .none
                }
                state.data?.selectedCar = car
                state.data?.refresh()
                state.templateState = .didChangeData()
                state.destination = nil
                return .none
            case let .didSelectTimeOption(timeOption):
                guard let timeOption else {
                    state.destination = nil
                    return .none
                }
                state.data?.selectedTimeOption = timeOption
                state.data?.refresh()
                state.templateState = .didChangeData()
                state.destination = nil
                return .none
            case .destination:
                return .none
            case let .didPreauthorizeParking(response):
                guard let data = state.data else { return .none }
                state.destination = .confirmParking(CarPlayConfirmParkingReducer.State(preauthResponse: response, model: data))
                return .none
            case let .error(error):
                let errorTitle = errorParser.getMessage(error: error)
                state.templateState = .error(.init(
                    type: .preauthorizeError,
                    title: errorTitle,
                    description: nil,
                    buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                ))
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    private func loadData(subareaHint: String?) -> Effect<Action> {
        return .run { send in
            do {
                let data = try reducerClient.loadData(subareaHint: subareaHint)
                await send(.didLoadData(data))
            } catch {
                await send(.refresh)
            }
        }
    }

    private func loadAccounts() -> Effect<Action> {
        return .run { send in
            do {
                let accounts = try reducerClient.loadAccounts()
                await send(.didLoadAccounts(accounts))
            } catch {
                await send(.refresh)
            }
        }
    }

    private func loadSelectedCity() -> Effect<Action> {
        return .run { send in
            do {
                let city = try reducerClient.loadSelectedCity()
                await send(.didLoadSelectedCity(city))
            } catch {
                await send(.refresh)
            }
        }
    }

    private func loadCars() -> Effect<Action> {
        return .run { send in
            do {
                let cars = try reducerClient.loadCars()
                await send(.didLoadCars(cars))
            } catch {
                await send(.refresh)
            }
        }
    }

    private func validateForm(model: CarPlayParkingsNewParkingFormModel) -> Effect<Action> {
        return .run { send in
            var errors: [BuyTicketFormValidationError] = []
            if model.selectedCar == nil {
                errors.append(.carNotSelected)
            }
            if (model.selectedSubarea != nil || model.selectedTicket != nil) == false {
                errors.append(.areaNotSelected)
            }
            if model.selectedTimeOption == nil {
                errors.append(.timeOptionNotSelected)
            }
            if model.selectedAccount == nil {
                errors.append(.carNotSelected)
            }
            if errors.isEmpty {
                await send(.onValidationFormSuccess)
            } else {
                await send(.onValidationFormError(errors))
            }
        }
    }

    private func preauthorizeParking(data: CarPlayParkingsNewParkingFormModel) -> Effect<Action> {
        return .run { send in
            do {
                try await reducerClient.createAuthSession()
                let parking = try await reducerClient.preauthorizeParking(data)
                await send(.didPreauthorizeParking(parking))
            } catch {
                await send(.error(error))
            }
        }
    }
}
