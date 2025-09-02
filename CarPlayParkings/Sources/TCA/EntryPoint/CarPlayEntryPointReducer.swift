import CarPlay
import ComposableArchitecture
import Dependencies
import IKOCommon

@Reducer
struct CarPlayEntryPointReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?

        var templateState: TemplateState = .willAppear
    }

    enum TemplateState: Equatable {
        case willAppear
        case loading(String)
        case error(CarPlayErrorTemplateModel<CarPlayEntryPointFeatureErrorType>)

        static func == (lhs: TemplateState, rhs: TemplateState) -> Bool {
            switch (lhs, rhs) {
            case (.willAppear, .willAppear),
                (.loading, .loading),
                (.error, .error):
                return true
            default:
                return false
            }
        }
    }

    enum Action: Sendable {
        case destination(PresentationAction<Destination.Action>)
        case onAppear
        case refresh
        case onErrorButtonTap(CarPlayEntryPointFeatureErrorType)
        case onCheckRequirementsError(String)
        case onCheckRequirementsSuccess
        case onLoadParkingDataSuccess
        case onLoadParkingDataError(errorMessage: String)
        case onCheckMobiletIdAndCarListSuccess
        case onCheckMobiletIdAndCarListError
        case onCheckLocationPermissionSuccess
        case onCheckLocationPermissionError
        case onActiveTicket(CarPlayParkingsTicketListItem, MKMapItem)
        case onInactiveTicket
    }

    @Reducer(state: .equatable)
    enum Destination {
        case inactiveTicket(CarPlayInactiveTicketReducer)
        case activeTicket(CarPlayActiveTicketReducer)
    }

    @Dependency(\.entryPointReducerClient) private var reducerClient
    @Dependency(\.carPlayParkingsErrorParser) private var errorParser

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            case .onAppear, .refresh:
                if state.templateState != .loading("") {
                    state.templateState = .loading(reducerClient.resourceProvider.loadingSplashText)
                }
                return performCheckRequirements()
            case let .onCheckRequirementsError(errorMessage):
                state.templateState =
                    .error(.init(
                        type: .checkRequirementsError,
                        title: errorMessage,
                        description: nil,
                        buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                    ))
                return .none
            case .onCheckRequirementsSuccess:
                if state.templateState != .loading("") {
                    state.templateState = .loading(reducerClient.resourceProvider.loadingSplashText)
                }
                return perfomLoadParkingData()
            case .onLoadParkingDataSuccess:
                return performCheckMobiletIdAndCarList()
            case let .onLoadParkingDataError(errorMessage):
                state.templateState =
                    .error(.init(
                        type: .loadParkingDataError,
                        title: errorMessage,
                        description: nil,
                        buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                    ))
                return .none
            case .onCheckMobiletIdAndCarListSuccess:
                return performCheckLocation()
            case .onCheckMobiletIdAndCarListError:
                state.templateState =
                    .error(.init(
                        type: .checkMobiletIdAndCarListError,
                        title: reducerClient.resourceProvider.mobiletNotFoundText,
                        description: nil,
                        buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                    ))
                return .none
            case .onCheckLocationPermissionSuccess:
                return performGetActiveTicket()
            case .onCheckLocationPermissionError:
                state.templateState =
                    .error(.init(
                        type: .locationPermissionError,
                        title: reducerClient.resourceProvider.locationDisabledText,
                        description: nil,
                        buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                    ))
                return .none
            case let .onErrorButtonTap(errorType):
                if state.templateState != .loading("") {
                    state.templateState = .loading(reducerClient.resourceProvider.loadingSplashText)
                }
                switch errorType {
                case .locationPermissionError:
                    return performCheckLocation()
                case .checkMobiletIdAndCarListError:
                    return perfomLoadParkingData()
                case .loadParkingDataError:
                    return perfomLoadParkingData()
                case .checkRequirementsError:
                    return performCheckRequirements()
                }
            case let .onActiveTicket(ticket, location):
                state.destination = .activeTicket(CarPlayActiveTicketReducer.State(
                    activeTicket: ticket,
                    ticket: .init(
                        activeTicket: ticket,
                        resorceProvider: reducerClient.resourceProvider
                    ),
                    location: location
                ))
                return .none
            case .onInactiveTicket:
                state.destination = .inactiveTicket(CarPlayInactiveTicketReducer.State())
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
    }

    private func performCheckRequirements() -> Effect<Action> {
        return .run { send in
            if let requirementsError = reducerClient.checkRequirements() {
                await send(.onCheckRequirementsError(requirementsError))
            } else {
                await send(.onCheckRequirementsSuccess)
            }
        }
    }

    private func perfomLoadParkingData() -> Effect<Action> {
        return .run { send in
            do {
                try await reducerClient.getParkingData()
                await send(.onLoadParkingDataSuccess)
            } catch {
                let message: String = errorParser.getMessage(error: error)
                await send(.onLoadParkingDataError(errorMessage: message))
            }
        }
    }

    private func performCheckMobiletIdAndCarList() -> Effect<Action> {
        return .run { send in
            do {
                try reducerClient.checkMobiletIdAndCarList()
                await send(.onCheckMobiletIdAndCarListSuccess)
            } catch {
                await send(.onCheckMobiletIdAndCarListError)
            }
        }
    }

    private func performCheckLocation() -> Effect<Action> {
        return .run { send in
            let result = await reducerClient.checkLocationPermissions()
            switch result {
            case .disabled:
                await send(.onCheckLocationPermissionError)
            case .enabled:
                await send(.onCheckLocationPermissionSuccess)
            }
        }
    }

    private func performGetActiveTicket() -> Effect<Action> {
        return .run { send in
            if let activeTicket = reducerClient.getActiveTicket() {
                do {
                    let location = try reducerClient.getLocation()
                    await send(.onActiveTicket(activeTicket, location))
                } catch {
                    await send(.onCheckLocationPermissionError)
                }
            } else {
                await send(.onInactiveTicket)
            }
        }
    }
}
