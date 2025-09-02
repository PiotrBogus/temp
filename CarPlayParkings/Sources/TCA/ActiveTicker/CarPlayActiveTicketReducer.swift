import CarPlay
import ComposableArchitecture
import Dependencies
import ParkingPlaces

@Reducer
struct CarPlayActiveTicketReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var templateState: TemplateState = .didAppear
        let activeTicket: CarPlayParkingsTicketListItem
        let ticket: CarPlayParkingsActiveTicketOverviewModel
        let location: MKMapItem
    }

    enum TemplateState: Equatable {
        case didAppear
        case stopTicket
        case error(CarPlayErrorTemplateModel<CarPlayActiveTicketErrorType>)
        case entryPoint
    }

    enum Action: Sendable {
        case onStopTicket
        case onTicketExpired
        case onStopTicketSuccess
        case onStopTicketFail(Error)
        case onTryAgain
    }

    @Dependency(\.carPlayParkingsErrorParser) private var errorParser
    @Dependency(\.activeTicketReducerClient) private var reducerClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onStopTicket, .onTryAgain:
                state.templateState = .stopTicket
                return stopTicket(ticket: state.activeTicket)
            case .onStopTicketSuccess, .onTicketExpired:
                state.templateState = .entryPoint
                return notifyParkingWidgetAndEntryPoint(activeTicket: state.activeTicket)
            case let .onStopTicketFail(error):
                let errorTitle = errorParser.getMessage(error: error)
                state.templateState = .error(.init(
                    type: .stopParkingError,
                    title: errorTitle,
                    description: nil,
                    buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                ))
                return .none
            }
        }
    }

    private func stopTicket(ticket: CarPlayParkingsTicketListItem) -> Effect<Action> {
        return .run { send in
            do {
                try await reducerClient.stopTicket(ticket)
                await send(.onStopTicketSuccess)
            } catch {
                await send(.onStopTicketFail(error))
            }
        }
    }

    private func notifyParkingWidgetAndEntryPoint(activeTicket: CarPlayParkingsTicketListItem) -> Effect<Action> {
        return .run { _ in
            await MainActor.run {
                IKOParkingPlacesStopParkingHelper.notifyParkingStopped(activeTicket)
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: kIKOParkingPlacesListRefresh),
                    object: nil
                )
            }
        }
    }
}
