import XCTest
import ComposableArchitecture
@testable import YourModuleName

final class CarPlayZoneSelectionReducerTests: XCTestCase {

    // MARK: - Fixtures
    private let fixtureLocation = CarPlayParkingsLocation(latitude: 52.0, longitude: 21.0)
    private let fixtureTariff = CarPlayParkingsTarrifListItem(
        id: "t1",
        name: "Tariff 1",
        price: "5.00"
    )

    private lazy var fixtureCity = CarPlayParkingsCity(
        name: "Warsaw",
        extCityId: "001",
        location: fixtureLocation,
        distance: "1km",
        tarrifs: [fixtureTariff],
        canLocateSubareaWithGps: true
    )

    private let fixtureZone = CarPlayParkingsSubareaListItem(
        id: "z1",
        name: "Zone 1",
        distance: "0.5km"
    )

    // MARK: - Test onZoneSelection
    func testOnZoneSelection_SendsDelegateWithSelectedZone() async {
        let store = TestStore(
            initialState: CarPlayZoneSelectionReducer.State(city: fixtureCity),
            reducer: { CarPlayZoneSelectionReducer() }
        )

        await store.send(.onZoneSelection(fixtureZone))
        await store.receive(.delegate(.dismissZoneSelection(fixtureZone)))
    }

    // MARK: - Test didPop
    func testDidPop_SendsDelegateWithNil() async {
        let store = TestStore(
            initialState: CarPlayZoneSelectionReducer.State(city: fixtureCity),
            reducer: { CarPlayZoneSelectionReducer() }
        )

        await store.send(.didPop)
        await store.receive(.delegate(.dismissZoneSelection(nil)))
    }

    // MARK: - Test delegate action does not change state
    func testDelegate_DoesNotChangeState() async {
        let initialState = CarPlayZoneSelectionReducer.State(city: fixtureCity)
        let store = TestStore(
            initialState: initialState,
            reducer: { CarPlayZoneSelectionReducer() }
        )

        await store.send(.delegate(.dismissZoneSelection(fixtureZone)))
        XCTAssertEqual(store.state, initialState)
    }
}
