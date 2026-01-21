import XCTest
import ComposableArchitecture
@testable import YourModuleName

final class BehavioralBiometricExplanationReducerTests: XCTestCase {

    // MARK: - Behex Mock

    private final class BehexMock: Behex {
        private(set) var registeredEvents: [Any] = []

        func register(event: Any) {
            registeredEvents.append(event)
        }
    }

    // MARK: - Helpers

    private func makeStore(
        isPrimaryButtonVisible: Bool = true,
        behex: BehexMock = BehexMock()
    ) -> TestStore<
        BehavioralBiometricExplanationReducer.State,
        BehavioralBiometricExplanationReducer.Action
    > {
        TestStore(
            initialState: BehavioralBiometricExplanationReducer.State(
                destination: nil,
                isPrimaryButtonVisible: isPrimaryButtonVisible,
                expandedId: nil
            )
        ) {
            BehavioralBiometricExplanationReducer(behex: behex)
        }
    }

    // MARK: - Tests

    func test_onAppear_doesNotChangeState() async {
        let behex = BehexMock()
        let store = makeStore(behex: behex)

        await store.send(.onAppear)

        XCTAssertEqual(behex.registeredEvents.count, 1)
        XCTAssertNil(store.state.destination)
        XCTAssertNil(store.state.expandedId)
    }

    func test_turnOnAdditionalSecurityButtonTap_navigatesToAgreements() async {
        let behex = BehexMock()
        let store = makeStore(behex: behex)

        await store.send(.onTurnOnAdditionalSecurityButtonTap) {
            $0.destination = .agreements
        }

        XCTAssertEqual(behex.registeredEvents.count, 1)
    }

    func test_showAllQuestionsAndAnswersButtonTap_navigatesToFAQ() async {
        let behex = BehexMock()
        let store = makeStore(behex: behex)

        await store.send(.onShowAllQuestionsAndAnswersButtonTap) {
            $0.destination = .faq
        }

        XCTAssertEqual(behex.registeredEvents.count, 1)
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
