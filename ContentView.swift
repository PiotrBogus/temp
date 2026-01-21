@testable import BehavioralBiometric
import Behex
import ComposableArchitecture
import XCTest

@MainActor
final class BehavioralBiometricExplanationReducerTests: XCTestCase {
    func test_turnOnAdditionalSecurityButtonTap_navigatesToAgreements() async {
        let store = makeStore()

        await store.send(.onTurnOnAdditionalSecurityButtonTap) {
            $0.destination = .agreements
        }
    }

    func test_showAllQuestionsAndAnswersButtonTap_navigatesToFAQ() async {
        let store = makeStore()

        await store.send(.onShowAllQuestionsAndAnswersButtonTap) {
            $0.destination = .faq
        }
    }

    func test_onQuestionTap_setsExpandedId() async {
        let store = makeStore()
        let id = UUID()

        await store.send(.onQuestionTap(id)) {
            $0.expandedId = id
        }
    }

    func test_onQuestionTap_withNil_clearsExpandedId() async {
        let store = makeStore(expandedId: UUID())

        await store.send(.onQuestionTap(nil)) {
            $0.expandedId = nil
        }
    }

    // MARK: - Helpers

    private func makeStore(
        isPrimaryButtonVisible: Bool = true,
        expandedId: UUID? = nil
    ) -> TestStore<
        BehavioralBiometricExplanationReducer.State,
        BehavioralBiometricExplanationReducer.Action
    > {
        TestStore(
            initialState: BehavioralBiometricExplanationReducer.State(
                destination: nil,
                isPrimaryButtonVisible: isPrimaryButtonVisible,
                expandedId: expandedId
            )
        ) {
            BehavioralBiometricExplanationReducer(behex: BehavioralBiometricBehexMock())
        }
    }
}
