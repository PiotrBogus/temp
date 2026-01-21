@testable import BehavioralBiometric
import Behex
import ComposableArchitecture
import Testing

struct BehavioralBiometricFAQReducerTests {

    @Test
    @MainActor
    func onAppear_registersBehexEvent_andDoesNotChangeState() async {
        let store = makeStore()

        await store.send(.onAppear)
    }

    @Test
    @MainActor
    func onQuestionTap_setsExpandedId() async {
        let store = makeStore()
        let id = UUID()

        await store.send(.onQuestionTap(id)) {
            $0.expandedId = id
        }
    }

    @Test
    @MainActor
    func onQuestionTap_withNil_clearsExpandedId() async {
        let store = makeStore(expandedId: UUID())

        await store.send(.onQuestionTap(nil)) {
            $0.expandedId = nil
        }
    }

    // MARK: - Helpers

    @MainActor
    private func makeStore(
        expandedId: UUID? = nil,
        behex: Behex = BehavioralBiometricBehexMock()
    ) -> TestStore<
        BehavioralBiometricFAQReducer.State,
        BehavioralBiometricFAQReducer.Action
    > {
        TestStore(
            initialState: BehavioralBiometricFAQReducer.State(
                expandedId: expandedId
            )
        ) {
            BehavioralBiometricFAQReducer(behex: behex)
        }
    }
}
