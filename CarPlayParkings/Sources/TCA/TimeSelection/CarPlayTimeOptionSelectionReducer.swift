import CarPlay
import ComposableArchitecture
import Dependencies

@Reducer
struct CarPlayTimeOptionSelectionReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var templateState: TemplateState = .didAppear
        var timeOptions: [CarPlayParkingsTariffTimeOption] = []
    }

    enum TemplateState: Equatable {
        case didAppear
        case fixedTimeOptionSelection([CarPlayParkingsTariffTimeOption])
    }

    enum Action: Sendable {
        case onFixedTimeOptionSelection([CarPlayParkingsTariffTimeOption])
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .onFixedTimeOptionSelection(timeOptions):
                state.templateState = .fixedTimeOptionSelection(timeOptions)
                return .none
            }
        }
    }
}
