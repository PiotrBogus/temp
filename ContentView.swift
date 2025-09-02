import XCTest
import ComposableArchitecture
@testable import YourModuleName

final class CarPlayTimeOptionSelectionReducerTests: XCTestCase {

    private let timeOption1: CarPlayParkingsTariffTimeOption = .minutes15
    private let timeOption2: CarPlayParkingsTariffTimeOption = .hour1
    private let timeOption3: CarPlayParkingsTariffTimeOption = .allDay

    func testInitialState_IsDidAppear() {
        let store = TestStore(
            initialState: CarPlayTimeOptionSelectionReducer.State(),
            reducer: { CarPlayTimeOptionSelectionReducer() }
        )

        XCTAssertEqual(store.state.templateState, .didAppear)
        XCTAssertEqual(store.state.timeOptions, [])
    }

    func testOnFixedTimeOptionSelection_UpdatesTemplateState() async {
        let store = TestStore(
            initialState: CarPlayTimeOptionSelectionReducer.State(),
            reducer: { CarPlayTimeOptionSelectionReducer() }
        )

        let selectedOptions: [CarPlayParkingsTariffTimeOption] = [timeOption1, timeOption2, timeOption3]

        await store.send(.onFixedTimeOptionSelection(selectedOptions)) {
            $0.templateState = .fixedTimeOptionSelection(selectedOptions)
        }
    }
}
