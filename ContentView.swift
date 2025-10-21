import XCTest
import ComposableArchitecture
@testable import YourModuleName // <- zamień na nazwę modułu, w którym jest reducer

@MainActor
final class CarPlayCarSelectionReducerTests: XCTestCase {

    func test_onInformationNavigationButtonTap_changesStateToInformation() async {
        // Given
        let store = TestStore(initialState: CarPlayCarSelectionReducer.State()) {
            CarPlayCarSelectionReducer()
        } withDependencies: {
            $0.carPlayLogger = .noop // zdefiniowany mock logger
        }

        // When
        await store.send(.onInformationNavigationButtonTap) {
            // Then
            // Sprawdź tylko, że stan zmienia się na .information(UUID)
            if case .information = $0.templateState {
                // OK
            } else {
                XCTFail("Expected .information, got \($0.templateState)")
            }
        }
    }

    func test_onInformationOkButtonTap_changesStateToDidAppear() async {
        // Given
        let store = TestStore(initialState: CarPlayCarSelectionReducer.State(
            templateState: .information(UUID())
        )) {
            CarPlayCarSelectionReducer()
        } withDependencies: {
            $0.carPlayLogger = .noop
        }

        // When
        await store.send(.onInformationOkButtonTap) {
            // Then
            $0.templateState = .didAppear
        }
    }

    func test_logger_isCalledForEachAction() async {
        // Given
        var loggedMessages: [String] = []

        let logger = CarPlayLogger { message, _, _ in
            loggedMessages.append(message)
        }

        let store = TestStore(initialState: CarPlayCarSelectionReducer.State()) {
            CarPlayCarSelectionReducer()
        } withDependencies: {
            $0.carPlayLogger = logger
        }

        // When
        await store.send(.onInformationNavigationButtonTap)
        await store.send(.onInformationOkButtonTap)

        // Then
        XCTAssertEqual(loggedMessages.count, 2)
        XCTAssertTrue(loggedMessages.contains { $0.contains("onInformationNavigationButtonTap") })
        XCTAssertTrue(loggedMessages.contains { $0.contains("onInformationOkButtonTap") })
    }
}
