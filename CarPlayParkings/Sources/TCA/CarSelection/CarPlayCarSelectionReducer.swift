import CarPlay
import ComposableArchitecture
import Dependencies

@Reducer
struct CarPlayCarSelectionReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var templateState: TemplateState = .didAppear
        var cars: [CarPlayParkingsCarListItem] = []
    }

    enum TemplateState: Equatable {
        case didAppear
    }

    enum Action: Sendable {
        case onCarSelection(CarPlayParkingsCarListItem)
        case delegate(Delegate)
        case didPop

        enum Delegate: Sendable, Equatable {
            case dismissCarSelection(CarPlayParkingsCarListItem?)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .delegate:
                return .none
            case let .onCarSelection(car):
                return .send(.delegate(.dismissCarSelection(car)))
            case .didPop:
                return .send(.delegate(.dismissCarSelection(nil)))
            }
        }
    }
}
