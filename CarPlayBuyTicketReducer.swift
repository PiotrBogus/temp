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
        case didChangeData
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
        case onSelectParkingTimeTap
        case onSelectAccountsTap
        case onSelectCarTap
        case didLoadAccounts([CarPlayParkingsAccount])
        case didLoadSelectedCity(CarPlayParkingsCity)
    }

    @Reducer(state: .equatable, .sendable, action: .sendable)
    enum Destination {
        case zoneSelection(CarPlayZoneSelectionReducer)
        case parkingTimeSelection
        case accountsSelection(CarPlayAccountSelectionReducer)
        case carSelection
    }

    @Dependency(\.buyTicketReducerClient) private var reducerClient
    @Dependency(\.carPlayParkingsErrorParser) private var errorParser

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return loadData(subareaHint: state.subareaHint)
            case let .didLoadData(data):
                state.data = data
                state.templateState = .didAppear
                return .none
            case .onSelectZoneTap:
                return loadSelectedCity()
            case let .didLoadSelectedCity(city):
                state.destination = .zoneSelection(CarPlayZoneSelectionReducer.State(city: city))
                return .none
            case .onSelectParkingTimeTap:
                state.destination = .parkingTimeSelection
                return .none
            case .onSelectAccountsTap:
                return loadAccounts()
            case let .didLoadAccounts(accounts):
                state.destination = .accountsSelection(CarPlayAccountSelectionReducer.State(accounts: accounts))
                return .none
            case .onSelectCarTap:
                state.destination = .carSelection
                return .none
            case .onNextButtonTap:
                guard let data = state.data else { return .none }
                return validateForm(model: data)
            case .onValidationFormSuccess:
                // navigate to next view
                return .none
            case let .onValidationFormError(errors):
                print(errors)
                // present error
                return .none
            case .refresh:
                state.templateState = .loading(reducerClient.resourceProvider.loadingSplashText)
                return .none
            case let .onErrorButtonTap(type):
                state.templateState = .loading(reducerClient.resourceProvider.loadingSplashText)
                switch type {
                default:
                    return .none
                }
            case .destination(.presented(.accountsSelection(.delegate(.dismissAccountSelection(let account))))):
                state.data?.selectedAccount = account
                state.data?.refresh()
                state.templateState = .didChangeData
                state.destination = nil
                return .none
            case .destination(.presented(.zoneSelection(.delegate(.dismissZoneSelection(let zone))))):
                state.data?.selectedSubarea = zone
                state.data?.refresh()
                state.templateState = .didChangeData
                state.destination = nil
                return .none
            case .destination:
                return .none
            }
        }
//        .ifLet(\.$destination, action: \.destination) {
//            Destination.body
//        }
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
}
