import XCTest
import ComposableArchitecture
@testable import YourModuleName

final class BehavioralBiometricFAQReducerTests: XCTestCase {

    // MARK: - Behex Mock

    private final class BehexMock: Behex {
        private(set) var registeredEvents: [Any] = []

        func register(event: Any) {
            registeredEvents.append(event)
        }
    }

    // MARK: - Helpers

    private func makeStore(
        behex: BehexMock = BehexMock()
    ) -> TestStore<
        BehavioralBiometricFAQReducer.State,
        BehavioralBiometricFAQReducer.Action
    > {
        TestStore(
            initialState: BehavioralBiometricFAQReducer.State(
                expandedId: nil
            )
        ) {
            BehavioralBiometricFAQReducer(behex: behex)
        }
    }

    // MARK: - Tests

    func test_onAppear_registersBehexEvent_andDoesNotChangeState() async {
        let behex = BehexMock()
        let store = makeStore(behex: behex)

        let initialState = store.state

        await store.send(.onAppear)

        XCTAssertEqual(behex.registeredEvents.count, 1)
        XCTAssertEqual(store.state, initialState)
    }

    func test_onQuestionTap_setsExpandedId() async {
        let store = makeStore()
        let id = UUID()

        await store.send(.onQuestionTap(id)) {
            $0.expandedId = id
        }
    }

    func test_onQuestionTap_withNil_clearsExpandedId() async {
        let store = makeStore()

        await store.send(.onQuestionTap(nil)) {
            $0.expandedId = nil
        }
    }
}
