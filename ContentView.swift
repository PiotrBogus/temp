@testable import BehavioralBiometric
import Behex
import ComposableArchitecture
import XCTest

@MainActor
final class BehavioralBiometricFAQReducerTests: XCTestCase {
    func test_onAppear_registersBehexEvent_andDoesNotChangeState() async {
        let store = makeStore()

        await store.send(.onAppear)
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
