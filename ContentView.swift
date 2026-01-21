@preconcurrency import Behex
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
        case onAppear
    }

    private let behex: Behex

    init(behex: Behex) {
        self.behex = behex
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                behex.register(event: .BehavioralBiometric_AllQuestionsScreen_view_Show)
                return .none

            case .onQuestionTap(let id):
                state.expandedId = id
                return .none
            }
        }
    }
}
