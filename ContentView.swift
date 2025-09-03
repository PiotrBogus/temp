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
        var isTimerRunning: Bool = false
    }

    enum TemplateState: Equatable {
        case didAppear
        case stopTicket
        case error(CarPlayErrorTemplateModel<CarPlayActiveTicketErrorType>)
        case entryPoint
    }

    enum Action: Sendable, Equatable {
        case onAppear
        case onDisappear
        case onStopTicket
        case onTicketExpired
        case onStopTicketSuccess
        case onStopTicketFail(String) // zamiast `Error`, żeby było Equatable
        case onTryAgain
        case _tick // wewnętrzna akcja od timera
    }

    @Dependency(\.carPlayParkingsErrorParser) private var errorParser
    @Dependency(\.activeTicketReducerClient) private var reducerClient
    @Dependency(\.continuousClock) private var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isTimerRunning else { return .none }
                state.isTimerRunning = true
                return startTimer(until: state.activeTicket.validToTimestamp)

            case .onDisappear:
                state.isTimerRunning = false
                return .cancel(id: CancelID.timer)

            case ._tick:
                if Date().millisecondsSinceEpoch >= state.activeTicket.validToTimestamp {
                    return .send(.onTicketExpired)
                }
                return .none

            case .onStopTicket, .onTryAgain:
                state.templateState = .stopTicket
                return stopTicket(ticket: state.activeTicket)

            case .onStopTicketSuccess, .onTicketExpired:
                state.templateState = .entryPoint
                return notifyParkingWidgetAndEntryPoint(activeTicket: state.activeTicket)

            case let .onStopTicketFail(message):
                state.templateState = .error(.init(
                    type: .stopParkingError,
                    title: message,
                    description: nil,
                    buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                ))
                return .none
            }
        }
    }

    // MARK: - Timer
    private func startTimer(until validTo: Int64) -> Effect<Action> {
        .run { send in
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(._tick)
            }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
    }

    // MARK: - Stop ticket
    private func stopTicket(ticket: CarPlayParkingsTicketListItem) -> Effect<Action> {
        .run { send in
            do {
                try await reducerClient.stopTicket(ticket)
                await send(.onStopTicketSuccess)
            } catch {
                let message = errorParser.getMessage(error: error)
                await send(.onStopTicketFail(message))
            }
        }
    }

    // MARK: - Notify
    private func notifyParkingWidgetAndEntryPoint(activeTicket: CarPlayParkingsTicketListItem) -> Effect<Action> {
        .run { _ in
            await MainActor.run {
                IKOParkingPlacesStopParkingHelper.notifyParkingStopped(activeTicket)
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: kIKOParkingPlacesListRefresh),
                    object: nil
                )
            }
        }
    }

    // MARK: - CancelID
    private enum CancelID {
        case timer
    }
}

private extension Date {
    var millisecondsSinceEpoch: Int64 {
        Int64(self.timeIntervalSince1970 * 1000)
    }
}
