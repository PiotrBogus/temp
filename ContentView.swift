import CarPlay
import ComposableArchitecture
import Dependencies

@Reducer
struct CarPlayCarSelectionReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var templateState: TemplateState = .willAppear

        var cars: [CarPlayParkingsCarListItem] = []
    }

    enum TemplateState: Equatable {
        case willAppear
        case didAppear
        case information(UUID)
    }

    enum Action: Sendable, Equatable {
        case onInformationNavigationButtonTap
        case onInformationOkButtonTap
    }

    @Dependency(\.carPlayLogger) var logger

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            logger.log("\(String(describing: #function)) action: \(String(describing: action))", nil, String(describing: Self.self))
            switch action {
            case .onInformationNavigationButtonTap:
                state.templateState = .information(UUID())
                return .none
            case .onInformationOkButtonTap:
                state.templateState = .didAppear
                return .none
            }
        }
    }
}
