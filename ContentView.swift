import XCTest
import ComposableArchitecture
@testable import YourModuleName

final class CarPlayCarSelectionReducerTests: XCTestCase {

    // MARK: - Fixtures
    private let defaultCar = CarPlayParkingsCarListItem(
        1, extPlateId: "ext1", name: "Default Car", plate: "ABC123", defaultPlate: true
    )
    
    private let secondaryCar = CarPlayParkingsCarListItem(
        2, extPlateId: "ext2", name: "Secondary Car", plate: "XYZ789", defaultPlate: false
    )

    // MARK: - Test onCarSelection
    func testOnCarSelection_SendsDelegateWithSelectedCar() async {
        let store = TestStore(
            initialState: CarPlayCarSelectionReducer.State(cars: [defaultCar, secondaryCar]),
            reducer: { CarPlayCarSelectionReducer() }
        )

        await store.send(.onCarSelection(defaultCar))
        await store.receive(.delegate(.dismissCarSelection(defaultCar)))
    }

    // MARK: - Test didPop
    func testDidPop_SendsDelegateWithNil() async {
        let store = TestStore(
            initialState: CarPlayCarSelectionReducer.State(cars: [defaultCar, secondaryCar]),
            reducer: { CarPlayCarSelectionReducer() }
        )

        await store.send(.didPop)
        await store.receive(.delegate(.dismissCarSelection(nil)))
    }

    // MARK: - Test delegate action does not mutate state
    func testDelegate_DoesNotChangeState() async {
        let initialState = CarPlayCarSelectionReducer.State(cars: [defaultCar, secondaryCar])
        let store = TestStore(
            initialState: initialState,
            reducer: { CarPlayCarSelectionReducer() }
        )

        await store.send(.delegate(.dismissCarSelection(defaultCar)))
        XCTAssertEqual(store.state, initialState)
    }
}
