import ComposableArchitecture
import Foundation

@Reducer
struct BehavioralBiometricExplanationReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?
        let isPrimaryButtonVisible: Bool
        let questionsAndAnswersItems: [BehavioralBiometricQuestionAndAnswerItem] = BehavioralBiometricQuestionAndAnswerItem.explanation

        var expandedId: UUID?
    }

    @Reducer(state: .equatable, .sendable, action: .sendable)
    public enum Destination {
        case faq(BehavioralBiometricFAQReducer)
        case agreements
    }

    enum Action: Sendable {
        case onTurnOnAdditionalSecurityButtonTap
        case onShowAllQuestionsAndAnswersButtonTap
        case onQuestionTap(UUID?)
        case destination(PresentationAction<Destination.Action>)
        case onResetDestination
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onTurnOnAdditionalSecurityButtonTap:
                state.destination = .agreements
                return .none
            case .onShowAllQuestionsAndAnswersButtonTap:
                state.destination = .faq(.init())
                return .none
            case let .onQuestionTap(id):
                state.expandedId = id
                return .none
            case .destination:
                return .none
            case .onResetDestination:
                state.destination = nil
                return .none
            }
        }
    }
}
