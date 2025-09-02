import XCTest
import ComposableArchitecture
import MapKit
@testable import YourModuleName

// MARK: - Fixtures

extension MKMapItem {
    static var mock: MKMapItem {
        MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
    }
}

extension CarPlayParkingsTicketListItem {
    static var fixtureDefault: CarPlayParkingsTicketListItem {
        CarPlayParkingsTicketListItem(ticketId: 1, plate: "XYZ123", startTime: Date(), endTime: Date())
    }
}

// MARK: - Mock EntryPointClient

struct MockEntryPointClient {
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
                else { return .mock }
            }
        )
    }
}

// MARK: - Test Class

final class CarPlayEntryPointReducerTests: XCTestCase {

    func testOnAppear_FullSuccessFlow() async {
        await withDependencies {
            $0.entryPointReducerClient = MockEntryPointClient.make()
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(loadingSplashText: "Loading")
        } operation: {
            let store = TestStore(
                initialState: CarPlayEntryPointReducer.State(),
                reducer: CarPlayEntryPointReducer()
            )

            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }

            await store.receive(.onCheckRequirementsSuccess, timeout: 1)
            await store.receive(.onLoadParkingDataSuccess, timeout: 1)
            await store.receive(.onCheckMobiletIdAndCarListSuccess, timeout: 1)
            await store.receive(.onCheckLocationPermissionSuccess, timeout: 1)
            await store.receive(.onInactiveTicket, timeout: 1)
        }
    }

    func testCheckRequirementsError() async {
        await withDependencies {
            $0.entryPointReducerClient = MockEntryPointClient.make(checkRequirementsResult: "Requirements failed")
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(alertButtonTryAgainText: "Retry")
        } operation: {
            let store = TestStore(
                initialState: CarPlayEntryPointReducer.State(),
                reducer: CarPlayEntryPointReducer()
            )

            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }

            await store.receive(.onCheckRequirementsError("Requirements failed"), timeout: 1) {
                $0.templateState = .error(
                    .init(
                        type: .checkRequirementsError,
                        title: "Requirements failed",
                        description: nil,
                        buttonTitle: "Retry"
                    )
                )
            }
        }
    }

    func testLoadParkingDataError() async {
        await withDependencies {
            $0.entryPointReducerClient = MockEntryPointClient.make(getParkingDataSucceeds: false)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(
                alertButtonTryAgainText: "Retry",
                loadingSplashText: "Loading"
            )
        } operation: {
            let store = TestStore(
                initialState: CarPlayEntryPointReducer.State(),
                reducer: CarPlayEntryPointReducer()
            )

            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }

            await store.receive(.onCheckRequirementsSuccess, timeout: 1)
            await store.receive(.onLoadParkingDataError(errorMessage: "The operation couldn’t be completed. (Test error 1.)"), timeout: 1) {
                $0.templateState = .error(.init(
                    type: .loadParkingDataError,
                    title: "The operation couldn’t be completed. (Test error 1.)",
                    description: nil,
                    buttonTitle: "Retry"
                ))
            }
        }
    }

    func testMobiletIdAndCarListError() async {
        await withDependencies {
            $0.entryPointReducerClient = MockEntryPointClient.make(mobiletIdExists: false)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(
                alertButtonTryAgainText: "Retry",
                mobiletNotFoundText: "Mobilet not found",
                loadingSplashText: "Loading"
            )
        } operation: {
            let store = TestStore(
                initialState: CarPlayEntryPointReducer.State(),
                reducer: CarPlayEntryPointReducer()
            )

            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }

            await store.receive(.onCheckRequirementsSuccess, timeout: 1)
            await store.receive(.onLoadParkingDataSuccess, timeout: 1)
            await store.receive(.onCheckMobiletIdAndCarListError, timeout: 1) {
                $0.templateState = .error(.init(
                    type: .checkMobiletIdAndCarListError,
                    title: "Mobilet not found",
                    description: nil,
                    buttonTitle: "Retry"
                ))
            }
        }
    }

    func testCheckLocationPermissionError() async {
        await withDependencies {
            $0.entryPointReducerClient = MockEntryPointClient.make(locationEnabled: false)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(
                alertButtonTryAgainText: "Retry",
                loadingSplashText: "Loading",
                locationDisabledText: "Location Off"
            )
        } operation: {
            let store = TestStore(
                initialState: CarPlayEntryPointReducer.State(),
                reducer: CarPlayEntryPointReducer()
            )

            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }

            await store.receive(.onCheckRequirementsSuccess, timeout: 1)
            await store.receive(.onLoadParkingDataSuccess, timeout: 1)
            await store.receive(.onCheckMobiletIdAndCarListSuccess, timeout: 1)
            await store.receive(.onCheckLocationPermissionError, timeout: 1) {
                $0.templateState = .error(.init(
                    type: .locationPermissionError,
                    title: "Location Off",
                    description: nil,
                    buttonTitle: "Retry"
                ))
            }
        }
    }

    func testActiveTicketGetLocationError() async {
        await withDependencies {
            $0.entryPointReducerClient = MockEntryPointClient.make(hasActiveTicket: true, getLocationThrows: true)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(loadingSplashText: "Loading")
        } operation: {
            let store = TestStore(
                initialState: CarPlayEntryPointReducer.State(),
                reducer: CarPlayEntryPointReducer()
            )

            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }

            await store.receive(.onCheckRequirementsSuccess, timeout: 1)
            await store.receive(.onLoadParkingDataSuccess, timeout: 1)
            await store.receive(.onCheckMobiletIdAndCarListSuccess, timeout: 1)
            await store.receive(.onCheckLocationPermissionSuccess, timeout: 1)
            await store.receive(.onCheckLocationPermissionError, timeout: 1)
        }
    }

    func testInactiveTicketFlow() async {
        await withDependencies {
            $0.entryPointReducerClient = MockEntryPointClient.make(hasActiveTicket: false)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(loadingSplashText: "Loading")
        } operation: {
            let store = TestStore(
                initialState: CarPlayEntryPointReducer.State(),
                reducer: CarPlayEntryPointReducer()
            )

            await store.send(.onAppear) {
                $0.templateState = .loading("Loading")
            }

            await store.receive(.onCheckRequirementsSuccess, timeout: 1)
            await store.receive(.onLoadParkingDataSuccess, timeout: 1)
            await store.receive(.onCheckMobiletIdAndCarListSuccess, timeout: 1)
            await store.receive(.onCheckLocationPermissionSuccess, timeout: 1)
            await store.receive(.onInactiveTicket, timeout: 1)
        }
    }
}
