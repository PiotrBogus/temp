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
        case refresh
        case template(Template)
        case effect(Effect)

        enum Effect: Sendable {
            case didLoadData(CarPlayParkingsNewParkingFormModel)
            case onValidationFormError([BuyTicketFormValidationError])
            case onValidationFormSuccess
            case didLoadAccounts([CarPlayParkingsAccount])
            case didLoadSelectedCity(CarPlayParkingsCity)
            case didLoadCars([CarPlayParkingsCarListItem])
            case didPreauthorizeParking(CarPlayParkingsPreauthResponse)
            case error(Error)
        }

        enum Template: Sendable {
            case onNextButtonTap
            case onSelectZoneTap
            case onSelectTimeOptionsTap
            case onSelectAccountsTap
            case onSelectCarTap
            case onSelectTimeOption(CarPlayParkingsTariffTimeOption?)
            case onErrorButtonTap(CarPlayBuyTicketFeatureErrorType)
        }
    }

    @Reducer(state: .equatable, .sendable, action: .sendable)
    enum Destination {
        case zoneSelection(CarPlayZoneSelectionReducer)
        case timeOptionSelection(CarPlayTimeOptionSelectionReducer)
        case accountsSelection(CarPlayAccountSelectionReducer)
        case carSelection(CarPlayCarSelectionReducer)
        case confirmParking(CarPlayConfirmParkingReducer)
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
            case let .template(action):
                return handleTemplateAction(action: action, state: &state)
            case let .effect(action):
                return handleEffectAction(action: action, state: &state)
            case .refresh:
                state.templateState = .loading(reducerClient.resourceProvider.loadingSplashText)
                return .none
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
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    private func handleTemplateAction(action: Action.Template, state: inout State) -> Effect<Action> {
        switch action {
        case .onNextButtonTap:
            guard let data = state.data else { return .none }
            return validateForm(model: data)
        case .onSelectZoneTap:
            return loadSelectedCity()
        case .onSelectTimeOptionsTap:
            let timeOptions = state.data?.selectedSubarea?.timeOptions ?? []
            state.destination = .timeOptionSelection(CarPlayTimeOptionSelectionReducer.State(timeOptions: timeOptions))
            return .none
        case .onSelectAccountsTap:
            return loadAccounts()
        case .onSelectCarTap:
            return loadCars()
        case let .onSelectTimeOption(timeOption):
            guard let timeOption else {
                state.destination = nil
                return .none
            }
            state.data?.selectedTimeOption = timeOption
            state.data?.refresh()
            state.templateState = .didChangeData()
            state.destination = nil
            return .none
        case .onErrorButtonTap:
            return .send(.template(.onNextButtonTap))
        }
    }

    private func handleEffectAction(action: Action.Effect, state: inout State) -> Effect<Action> {
        switch action {
        case let .didLoadData(data):
            state.data = data
            state.templateState = .didAppear
            return .none
        case .onValidationFormSuccess:
            guard let data = state.data else { return .none }
            state.templateState = .preauthNewParkingProcessingSplash
            return preauthorizeParking(data: data)
        case let .onValidationFormError(errors):
            state.templateState = .validationError(UUID(), errors)
            return .none
        case let .didLoadSelectedCity(city):
            state.destination = .zoneSelection(CarPlayZoneSelectionReducer.State(city: city))
            return .none
        case let .didLoadAccounts(accounts):
            state.destination = .accountsSelection(CarPlayAccountSelectionReducer.State(accounts: accounts))
            return .none
        case let .didLoadCars(cars):
            state.destination = .carSelection(CarPlayCarSelectionReducer.State(cars: cars))
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

    private func loadData(subareaHint: String?) -> Effect<Action> {
        return .run { send in
            do {
                let data = try reducerClient.loadData(subareaHint: subareaHint)
                await send(.effect(.didLoadData(data)))
            } catch {
                await send(.refresh)
            }
        }
    }

    private func loadAccounts() -> Effect<Action> {
        return .run { send in
            do {
                let accounts = try reducerClient.loadAccounts()
                await send(.effect(.didLoadAccounts(accounts)))
            } catch {
                await send(.refresh)
            }
        }
    }

    private func loadSelectedCity() -> Effect<Action> {
        return .run { send in
            do {
                let city = try reducerClient.loadSelectedCity()
                await send(.effect(.didLoadSelectedCity(city)))
            } catch {
                await send(.refresh)
            }
        }
    }

    private func loadCars() -> Effect<Action> {
        return .run { send in
            do {
                let cars = try reducerClient.loadCars()
                await send(.effect(.didLoadCars(cars)))
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
                await send(.effect(.onValidationFormSuccess))
            } else {
                await send(.effect(.onValidationFormError(errors)))
            }
        }
    }

    private func preauthorizeParking(data: CarPlayParkingsNewParkingFormModel) -> Effect<Action> {
        return .run { send in
            do {
                try await reducerClient.createAuthSession()
                let parking = try await reducerClient.preauthorizeParking(data)
                await send(.effect(.didPreauthorizeParking(parking)))
            } catch {
                await send(.effect(.error(error)))
            }
        }
    }
}
