import CarPlay
import ComposableArchitecture
import Dependencies

@Reducer
struct CarPlayLastUsedParkingDetailsReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?
        var templateState: TemplateState = .didAppear
        let model: CarPlayParkingsLastParkingDetailsModel
        let ticket: CarPlayParkingsTicketListItem
    }

    enum TemplateState: Equatable {
        case didAppear
        case loading
        case error(CarPlayErrorTemplateModel<CarPlayLastUsedParkingDetailsErrorType>)
    }

    enum Action: Sendable {
        case onConfirm
        case onCreateModelSuccess(CarPlayParkingsNewParkingFormModel)
        case onCreateModelFailure(Error)
        case onTryAgain
    }

    @Reducer(state: .equatable, .sendable, action: .sendable)
    enum Destination {
        case buyTicket(CarPlayBuyTicketReducer)
    }

    @Dependency(\.carPlayParkingsErrorParser) private var errorParser
    @Dependency(\.lastUsedParkingDetailsReducerClient) private var reducerClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onConfirm:
                state.templateState = .loading
                return prepareModel(ticket: state.ticket)
            case let .onCreateModelSuccess(model):
                state.destination = .buyTicket(CarPlayBuyTicketReducer.State(data: model))
                return .none
            case let .onCreateModelFailure(error):
                let errorTitle = errorParser.getMessage(error: error)
                state.templateState = .error(.init(
                    type: .timeOptionsError,
                    title: errorTitle,
                    description: nil,
                    buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                ))
                return .none
            case .onTryAgain:
                return .send(.onConfirm)
            }
        }
    }

    private func prepareModel(ticket: CarPlayParkingsTicketListItem) -> Effect<Action> {
        return .run { send in
            do {
                let timeOptions = try await reducerClient.getParkingTimeOptions(ticket.locationId, ticket.tariffId)
                let cars = try reducerClient.loadCars()
                let accounts = try reducerClient.loadAccounts()

                let model = CarPlayParkingsNewParkingFormModel(
                    ticket: ticket,
                    timeOptions: timeOptions,
                    cars: cars,
                    accounts: accounts,
                    resourceProvider: reducerClient.resourceProvider,
                    timeOptionsResourceProvider: reducerClient.resourceProvider
                )
                await send(.onCreateModelSuccess(model))
            } catch {
                await send(.onCreateModelFailure(error))
            }
        }
    }
}
