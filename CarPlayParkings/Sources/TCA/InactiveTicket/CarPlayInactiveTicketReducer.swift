import CarPlay
import ComposableArchitecture
import Dependencies

@Reducer
struct CarPlayInactiveTicketReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?

        var templateState: TemplateState = .willAppear
    }

    enum TemplateState: Equatable {
        case willAppear
        case loading(String)
        case error(CarPlayErrorTemplateModel<CarPlayInactiveTicketFeatureErrorType>)
        case inactiveTicket(CarPlayInactiveParkingTicketTemplateModel)
    }

    enum Action: Sendable {
        case destination(PresentationAction<Destination.Action>)
        case onAppear
        case refresh
        case onErrorButtonTap(CarPlayInactiveTicketFeatureErrorType)
        case onGetCityListSuccess
        case onGetCityListError(String)
        case onGetLastUsedParkingsSuccess
        case onGetLastUsedParkingsError(String)
        case onGatherData(CarPlayInactiveParkingTicketTemplateModel)
        case onGatherDataError
        case didSelectPOI(CPPointOfInterest)
        case didGetSubarea(String?)
        case resetDestination
        case onLastUsedParkingSelection(CarPlayParkingsTicketListItem)
    }

    @Reducer(state: .equatable)
    enum Destination {
        case buyTicket(CarPlayBuyTicketReducer)
        case lastUsedParkingDetails(CarPlayLastUsedParkingDetailsReducer)
    }

    @Dependency(\.inactiveTicketReducerClient) private var reducerClient
    @Dependency(\.carPlayParkingsErrorParser) private var errorParser

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            case .onAppear:
                return getCityList()
            case .refresh:
                state.templateState = .loading(reducerClient.resourceProvider.loadingSplashText)
                return getCityList()
            case let .onErrorButtonTap(type):
                state.templateState = .loading(reducerClient.resourceProvider.loadingSplashText)
                switch type {
                case .getCityListError:
                    return getCityList()
                case .getLastUsedParkingsError:
                    return getLastUsedParkings()
                case .gatherDataError:
                    return .none
                }
            case .onGetCityListSuccess:
                return getLastUsedParkings()
            case let .onGetCityListError(errorMessage):
                state.templateState = .error(.init(
                    type: .getCityListError,
                    title: errorMessage,
                    description: nil,
                    buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                ))
                return .none
            case .onGetLastUsedParkingsSuccess:
                return gatherData()
            case let .onGetLastUsedParkingsError(errorMessage):
                state.templateState = .error(.init(
                    type: .getLastUsedParkingsError,
                    title: errorMessage,
                    description: nil,
                    buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                ))
                return .none
            case let .onGatherData(model):
                state.templateState = .inactiveTicket(model)
                return .none
            case .onGatherDataError:
                state.templateState = .error(
                    .init(
                        type: .gatherDataError,
                        title: reducerClient.resourceProvider.unknownErrorText,
                        description: nil,
                        buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                    )
                )
                return .none
            case let .didSelectPOI(poi):
                state.templateState = .loading(reducerClient.resourceProvider.findZoneByGpsLoadingText)
                return getSubareaHint(poi: poi)
            case let .didGetSubarea(subareaHint):
                state.destination = .buyTicket(CarPlayBuyTicketReducer.State(subareaHint: subareaHint))
                return .none
            case .resetDestination:
                state.destination = nil
                return .none
            case let .onLastUsedParkingSelection(ticket):
                let model = CarPlayParkingsLastParkingDetailsModel(ticket: ticket, resourceProvider: reducerClient.resourceProvider)
                state.destination = .lastUsedParkingDetails(CarPlayLastUsedParkingDetailsReducer.State(model: model, ticket: ticket))
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
    }

    private func getCityList() -> Effect<Action> {
        return .run { send in
            do {
                try await reducerClient.getCityListByGps()
                await send(.onGetCityListSuccess)
            } catch {
                let message: String = errorParser.getMessage(error: error)
                await send(.onGetCityListError(message))
            }
        }
    }

    private func getLastUsedParkings() -> Effect<Action> {
        return .run { send in
            do {
                try await reducerClient.getLastUsedParkings()
                await send(.onGetLastUsedParkingsSuccess)
            } catch {
                let message: String = errorParser.getMessage(error: error)
                await send(.onGetCityListError(message))
            }
        }
    }

    private func gatherData() -> Effect<Action> {
        return .run { send in
            do {
                let model = try reducerClient.gatherData()
                await send(.onGatherData(model))
            } catch {
                await send(.onGatherDataError)
            }
        }
    }

    private func getSubareaHint(poi: CPPointOfInterest) -> Effect<Action> {
        return .run { send in
            let subareaHint = await reducerClient.getSubareaHint(poi)
            await send(.didGetSubarea(subareaHint))
        }
    }
}
