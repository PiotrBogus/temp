import ComposableArchitecture
import Foundation

@Reducer
struct BehavioralBiometricFAQReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        let questionsAndAnswersItems: [BehavioralBiometricQuestionAndAnswerItem] = BehavioralBiometricQuestionAndAnswerItem.faq

        var expandedId: UUID?
    }

    enum Action: Sendable {
        case onQuestionTap(UUID?)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .onQuestionTap(id):
                state.expandedId = id
                return .none
            }
        }
    }
}
