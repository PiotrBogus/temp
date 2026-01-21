@testable import BehavioralBiometric
import Behex
import ComposableArchitecture
import Testing

@MainActor
struct BehavioralBiometricExplanationReducerTests {

    @Test
    func turnOnAdditionalSecurityButtonTap_navigatesToAgreements() async {
        let store = makeStore()

        await store.send(.onTurnOnAdditionalSecurityButtonTap) {
            $0.destination = .agreements
        }
    }

    @Test
    func showAllQuestionsAndAnswersButtonTap_navigatesToFAQ() async {
        let store = makeStore()

        await store.send(.onShowAllQuestionsAndAnswersButtonTap) {
            $0.destination = .faq
        }
    }

    @Test
    func onQuestionTap_setsExpandedId() async {
        let store = makeStore()
        let id = UUID()

        await store.send(.onQuestionTap(id)) {
            $0.expandedId = id
        }
    }

    @Test
    func onQuestionTap_withNil_clearsExpandedId() async {
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
            BehavioralBiometricExplanationReducer(
                behex: BehavioralBiometricBehexMock()
            )
        }
    }
}
