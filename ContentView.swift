import XCTest
import ComposableArchitecture
import MapKit
@testable import YourModuleName

@MainActor
final class CarPlayInitialReducerTests: XCTestCase {
    func test_onAppear_withRequirementsError() async {
        let testErrorMessage = "Requirements failed"

        let store = TestStore(
            initialState: CarPlayInitialReducer.State(),
            reducer: { CarPlayInitialReducer() }
        ) {
            $0.initialReducerClient.checkRequirements = { testErrorMessage }
            $0.initialReducerClient.resourceProvider.loadingSplashText = "Loading..."
            $0.initialReducerClient.resourceProvider.alertButtonTryAgainText = "Try again"
            $0.carPlayParkingsErrorParser.getMessage = { _ in "ParsedError" }
        }

        await store.send(.onAppear) {
            $0.templateState = .loading("Loading...")
        }

        await store.receive(\.onCheckRequirementsError, testErrorMessage) {
            $0.templateState = .error(.init(
                type: .checkRequirementsError,
                title: testErrorMessage,
                description: nil,
                buttonTitle: "Try again"
            ))
        }
    }

    func test_onAppear_success_flow_to_loadParkingData() async {
        let store = TestStore(
            initialState: CarPlayInitialReducer.State(),
            reducer: { CarPlayInitialReducer() }
        ) {
            $0.initialReducerClient.checkRequirements = { nil }
            $0.initialReducerClient.getParkingData = {}
            $0.initialReducerClient.checkMobiletIdAndCarList = {}
            $0.initialReducerClient.checkLocationPermissions = { .disabled }
            $0.initialReducerClient.resourceProvider.loadingSplashText = "Loading..."
            $0.initialReducerClient.resourceProvider.alertButtonTryAgainText = "OK"
            $0.carPlayParkingsErrorParser.getMessage = { _ in "ErrorMsg" }
        }

        await store.send(.onAppear) {
            $0.templateState = .loading("Loading...")
        }

        await store.receive(\.onCheckRequirementsSuccess) {
            $0.templateState = .loading("Loading...")
        }

        await store.receive(\.onLoadParkingDataSuccess)
        await store.receive(\.onCheckMobiletIdAndCarListSuccess)
        await store.receive(\.onCheckLocationPermissionError) {
            $0.templateState = .error(.init(
                type: .locationPermissionError,
                title: "Location disabled",
                description: nil,
                buttonTitle: "OK"
            ))
        }
    }

    func test_onLoadParkingDataError_setsErrorTemplate() async {
        struct DummyError: Error {}
        let store = TestStore(
            initialState: CarPlayInitialReducer.State(),
            reducer: { CarPlayInitialReducer() }
        ) {
            $0.initialReducerClient.checkRequirements = { nil }
            $0.initialReducerClient.getParkingData = { throw DummyError() }
            $0.carPlayParkingsErrorParser.getMessage = { _ in "Network error" }
            $0.initialReducerClient.resourceProvider.alertButtonTryAgainText = "Retry"
            $0.initialReducerClient.resourceProvider.loadingSplashText = "Loading..."
        }

        await store.send(.onAppear) {
            $0.templateState = .loading("Loading...")
        }

        await store.receive(\.onCheckRequirementsSuccess)
        await store.receive(\.onLoadParkingDataError, "Network error") {
            $0.templateState = .error(.init(
                type: .loadParkingDataError,
                title: "Network error",
                description: nil,
                buttonTitle: "Retry"
            ))
        }
    }

    func test_onErrorButtonTap_retries_flow() async {
        let store = TestStore(
            initialState: CarPlayInitialReducer.State(
                templateState: .error(.init(
                    type: .checkRequirementsError,
                    title: "Error",
                    description: nil,
                    buttonTitle: "Retry"
                ))
            ),
            reducer: { CarPlayInitialReducer() }
        ) {
            $0.initialReducerClient.checkRequirements = { nil }
            $0.initialReducerClient.resourceProvider.loadingSplashText = "Loading..."
        }

        await store.send(.onErrorButtonTap(.checkRequirementsError)) {
            $0.templateState = .loading("Loading...")
        }

        await store.receive(\.onCheckRequirementsSuccess)
    }

    func test_onActiveTicket_setsDestination() async {
        let dummyTicket = CarPlayParkingsTicketListItem.mock
        let dummyLocation = MKMapItem()

        let store = TestStore(
            initialState: CarPlayInitialReducer.State(),
            reducer: { CarPlayInitialReducer() }
        ) {
            $0.initialReducerClient.resourceProvider.loadingSplashText = "Loading..."
        }

        await store.send(.onActiveTicket(dummyTicket, dummyLocation)) {
            $0.destination = .activeTicket(
                CarPlayActiveTicketReducer.State(
                    activeTicket: dummyTicket,
                    ticket: .init(
                        activeTicket: dummyTicket,
                        resorceProvider: $0.initialReducerClient.resourceProvider
                    ),
                    location: dummyLocation
                )
            )
        }
    }

    func test_onInactiveTicket_setsDestination() async {
        let store = TestStore(
            initialState: CarPlayInitialReducer.State(),
            reducer: { CarPlayInitialReducer() }
        )

        await store.send(.onInactiveTicket) {
            $0.destination = .inactiveTicket(CarPlayInactiveTicketReducer.State())
        }
    }
}
