import XCTest
import ComposableArchitecture
import MapKit
@testable import YourModuleName

final class CarPlayEntryPointReducerFullTests: XCTestCase {

    struct MockClient {
        static func make(
            checkRequirementsResult: String? = nil,
            getParkingDataSucceeds: Bool = true,
            mobiletIdExists: Bool = true,
            locationEnabled: Bool = true,
            hasActiveTicket: Bool = false,
            getLocationThrows: Bool = false
        ) -> CarPlayEntryPointReducerClient {
            
            CarPlayEntryPointReducerClient(
                checkRequirements: { checkRequirementsResult },
                getParkingData: {
                    if getParkingDataSucceeds { return }
                    else { throw NSError(domain: "Test", code: 1) }
                },
                checkMobiletIdAndCarList: {
                    if mobiletIdExists { return }
                    else { throw CarPlayError.mobiletNotFound }
                },
                checkLocationPermissions: { locationEnabled ? .enabled : .disabled },
                getActiveTicket: { hasActiveTicket ? CarPlayParkingsTicketListItem.fixtureDefault : nil },
                getLocation: {
                    if getLocationThrows { throw NSError(domain: "Test", code: 2) }
                    else { return MKMapItem() }
                }
            )
        }
    }

    // MARK: - Test checkRequirements error
    func testCheckRequirementsError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }
        )

        withDependencies {
            $0.entryPointReducerClient = MockClient.make(checkRequirementsResult: "Req failed")
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(alertButtonTryAgainText: "Retry")
        } operation: {
            await store.send(.onAppear) {
                $0.templateState = .loading("loading")
            }
        }

        await store.receive(.onCheckRequirementsError("Req failed")) {
            $0.templateState = .error(.init(
                type: .checkRequirementsError,
                title: "Req failed",
                description: nil,
                buttonTitle: "Retry"
            ))
        }
    }

    // MARK: - Test getParkingData error
    func testLoadParkingDataError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }
        )

        withDependencies {
            $0.entryPointReducerClient = MockClient.make(getParkingDataSucceeds: false)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(alertButtonTryAgainText: "Retry", loadingSplashText: "Loading")
        } operation: {
            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }
        }

        await store.receive(.onCheckRequirementsSuccess)
        await store.receive(.onLoadParkingDataError(errorMessage: "The operation couldn’t be completed. (Test error 1.)")) {
            $0.templateState = .error(.init(
                type: .loadParkingDataError,
                title: "The operation couldn’t be completed. (Test error 1.)",
                description: nil,
                buttonTitle: "Retry"
            ))
        }
    }

    // MARK: - Test mobiletId and CarList error
    func testMobiletIdAndCarListError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }
        )

        withDependencies {
            $0.entryPointReducerClient = MockClient.make(mobiletIdExists: false)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(
                alertButtonTryAgainText: "Retry",
                mobiletNotFoundText: "Mobilet not found",
                loadingSplashText: "Loading"
            )
        } operation: {
            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }
        }

        await store.receive(.onCheckRequirementsSuccess)
        await store.receive(.onLoadParkingDataSuccess)
        await store.receive(.onCheckMobiletIdAndCarListError) {
            $0.templateState = .error(.init(
                type: .checkMobiletIdAndCarListError,
                title: "Mobilet not found",
                description: nil,
                buttonTitle: "Retry"
            ))
        }
    }

    // MARK: - Test location permission error
    func testCheckLocationPermissionError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }
        )

        withDependencies {
            $0.entryPointReducerClient = MockClient.make(locationEnabled: false)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(alertButtonTryAgainText: "Retry", loadingSplashText: "Loading", locationDisabledText: "Location Off")
        } operation: {
            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }
        }

        await store.receive(.onCheckRequirementsSuccess)
        await store.receive(.onLoadParkingDataSuccess)
        await store.receive(.onCheckMobiletIdAndCarListSuccess)
        await store.receive(.onCheckLocationPermissionError) {
            $0.templateState = .error(.init(
                type: .locationPermissionError,
                title: "Location Off",
                description: nil,
                buttonTitle: "Retry"
            ))
        }
    }

    // MARK: - Test active ticket with getLocation error
    func testActiveTicketGetLocationError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }
        )

        withDependencies {
            $0.entryPointReducerClient = MockClient.make(hasActiveTicket: true, getLocationThrows: true)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(loadingSplashText: "Loading")
        } operation: {
            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }
        }

        await store.receive(.onCheckRequirementsSuccess)
        await store.receive(.onLoadParkingDataSuccess)
        await store.receive(.onCheckMobiletIdAndCarListSuccess)
        await store.receive(.onCheckLocationPermissionSuccess)
        await store.receive(.onCheckLocationPermissionError) // fallback due to getLocation error
    }

    // MARK: - Test inactive ticket
    func testInactiveTicketFlow() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }
        )

        withDependencies {
            $0.entryPointReducerClient = MockClient.make(hasActiveTicket: false)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(loadingSplashText: "Loading")
        } operation: {
            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }
        }

        await store.receive(.onCheckRequirementsSuccess)
        await store.receive(.onLoadParkingDataSuccess)
        await store.receive(.onCheckMobiletIdAndCarListSuccess)
        await store.receive(.onCheckLocationPermissionSuccess)
        await store.receive(.onInactiveTicket)
    }
}
