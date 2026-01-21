@preconcurrency import Behex
import ComposableArchitecture
import Foundation

@Reducer
struct BehavioralBiometricExplanationReducer: Sendable {
    @ObservableState
    struct State: Sendable {
        var destination: Destination?
        let isPrimaryButtonVisible: Bool
        let questionsAndAnswersItems: [BehavioralBiometricQuestionAndAnswerItem] = BehavioralBiometricQuestionAndAnswerItem.explanation

        var expandedId: UUID?
    }

    @CasePathable
    public enum Destination: Sendable {
        case faq
        case agreements
    }

    @CasePathable
    enum Action: Sendable {
        case onAppear
        case onTurnOnAdditionalSecurityButtonTap
        case onShowAllQuestionsAndAnswersButtonTap
        case onQuestionTap(UUID?)
    }

    private let behex: Behex

    init(behex: Behex) {
        self.behex = behex
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                behex.register(event: .BehavioralBiometric_InfoScreen_view_Show)
                return .none

            case .onTurnOnAdditionalSecurityButtonTap:
                behex.register(event: .BehavioralBiometric_InfoScreen_btn_TurnOn)
                state.destination = .agreements
                return .none

            case .onShowAllQuestionsAndAnswersButtonTap:
                behex.register(event: .BehavioralBiometric_InfoScreen_btn_AllQuestions)
                state.destination = .faq
                return .none

            case .onQuestionTap(let id):
                state.expandedId = id
                return .none
            }
        }
    }
}
