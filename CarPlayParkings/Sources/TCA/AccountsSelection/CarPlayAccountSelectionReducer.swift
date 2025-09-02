import CarPlay
import ComposableArchitecture
import Dependencies

@Reducer
struct CarPlayAccountSelectionReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var templateState: TemplateState = .didAppear
        var accounts: [CarPlayParkingsAccount] = []
    }

    enum TemplateState: Equatable {
        case didAppear
    }

    enum Action: Sendable {
        case onAccountSelection(CarPlayParkingsAccount)
        case delegate(Delegate)
        case didPop

        enum Delegate: Sendable, Equatable {
            case dismissAccountSelection(CarPlayParkingsAccount?)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .delegate:
                return .none
            case let .onAccountSelection(account):
                return .send(.delegate(.dismissAccountSelection(account)))
            case .didPop:
                return .send(.delegate(.dismissAccountSelection(nil)))
            }
        }
    }
}
