import XCTest
import ComposableArchitecture
@testable import YourModuleName // <-- podmień na nazwę modułu z reducerem

final class CarPlayAccountSelectionReducerTests: XCTestCase {
    @MainActor
    func test_onInformationNavigationButtonTap_changesTemplateStateToInformation() async {
        // Given
        let store = TestStore(initialState: CarPlayAccountSelectionReducer.State()) {
            CarPlayAccountSelectionReducer()
        } withDependencies: {
            $0.carPlayLogger = .noop // mock logger
        }

        // When
        await store.send(.onInformationNavigationButtonTap) {
            // Then
            // stan przechodzi na .information(UUID)
            // nie możemy porównać UUID dokładnie, więc tylko sprawdzamy typ
            if case .information = $0.templateState {
                // OK
            } else {
                XCTFail("Expected templateState to be .information")
            }
        }
    }

    @MainActor
    func test_onInformationOkButtonTap_changesTemplateStateToDidAppear() async {
        // Given
        let store = TestStore(initialState: CarPlayAccountSelectionReducer.State(
            templateState: .information(UUID())
        )) {
            CarPlayAccountSelectionReducer()
        } withDependencies: {
            $0.carPlayLogger = .noop
        }

        // When
        await store.send(.onInformationOkButtonTap) {
            // Then
            $0.templateState = .didAppear
        }
    }
}
