import CarPlay
import ComposableArchitecture
import Dependencies

@Reducer
struct CarPlayZoneSelectionReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var templateState: TemplateState = .didAppear
        var city: CarPlayParkingsCity?
    }

    enum TemplateState: Equatable {
        case didAppear
    }

    enum Action: Sendable {
        case onZoneSelection(CarPlayParkingsSubareaListItem)
        case delegate(Delegate)
        case didPop

        enum Delegate: Sendable, Equatable {
            case dismissZoneSelection(CarPlayParkingsSubareaListItem?)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .delegate:
                return .none
            case let .onZoneSelection(zone):
                return .send(.delegate(.dismissZoneSelection(zone)))
            case .didPop:
                return .send(.delegate(.dismissZoneSelection(nil)))
            }
        }
    }
}
