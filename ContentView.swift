import Combine
import ComposableArchitecture
import MapKit
@testable import CarPlayParkings
import XCTest

@MainActor
final class CarPlayEntryPointReducerTests: XCTestCase {
    private var cancellable: AnyCancellable?

    func testOnAppear_FullSuccessfulFlow() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }) {
                $0.entryPointReducerClient = MockEntryPointClient.make()
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(loadingSplashText: "Loading")
            }

        await store.send(.onAppear) {
            $0.templateState = .loading("Loading")
        }

        await store.receive(.onCheckRequirementsSuccess)
        await store.receive(.onLoadParkingDataSuccess)
        await store.receive(.onCheckMobiletIdAndCarListSuccess)
        await store.receive(.onCheckLocationPermissionSuccess)
        await store.receive(.onInactiveTicket)
    }

    func testCheckRequirementsError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() },
            withDependencies: {
                $0.entryPointReducerClient = MockEntryPointClient.make(checkRequirementsResult: "Requirements failed")
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(alertButtonTryAgainText: "Retry")
            }
        )

        await store.send(.onAppear) {
            $0.templateState = .loading("Loading")
        }

        await store.receive(.onCheckRequirementsError("Requirements failed")) {
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

    func testLoadParkingDataError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() },
            withDependencies: {
                $0.entryPointReducerClient = MockEntryPointClient.make(getParkingDataSucceeds: false)
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(
                    alertButtonTryAgainText: "Retry",
                    loadingSplashText: "Loading"
                )
            }
        )

        await store.send(.onAppear) {
            $0.templateState = .loading("Loading")
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

    func testMobiletIdAndCarListError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() },
            withDependencies: {
                $0.entryPointReducerClient = MockEntryPointClient.make(mobiletIdExists: false)
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(
                    alertButtonTryAgainText: "Retry",
                    loadingSplashText: "Loading",
                    mobiletNotFoundText: "Mobilet not found"
                )
            }
        )

        await store.send(.onAppear) {
            $0.templateState = .loading("Loading")
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

    func testCheckLocationPermissionError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() },
            withDependencies: {
                $0.entryPointReducerClient = MockEntryPointClient.make(locationEnabled: false)
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(
                    alertButtonTryAgainText: "Retry",
                    loadingSplashText: "Loading",
                    locationDisabledText: "Location Off"
                )
            }
        )
        await store.send(.onAppear) {
            $0.templateState = .loading("Loading")
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

    func testActiveTicketGetLocationError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() },
            withDependencies: {
                $0.entryPointReducerClient = MockEntryPointClient.make(hasActiveTicket: true, getLocationThrows: true)
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(loadingSplashText: "Loading")
            }
        )

        await store.send(.onAppear) {
            $0.templateState = .loading("Loading")
        }

        await store.receive(.onCheckRequirementsSuccess)
        await store.receive(.onLoadParkingDataSuccess)
        await store.receive(.onCheckMobiletIdAndCarListSuccess)
        await store.receive(.onCheckLocationPermissionSuccess)
        await store.receive(.onCheckLocationPermissionError)
    }

    func testInactiveTicketFlow() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() },
            withDependencies: {
                $0.entryPointReducerClient = MockEntryPointClient.make(hasActiveTicket: false)
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(loadingSplashText: "Loading")
            }
        )

        await store.send(.onAppear) {
            $0.templateState = .loading("Loading")
        }

        await store.receive(.onCheckRequirementsSuccess)
        await store.receive(.onLoadParkingDataSuccess)
        await store.receive(.onCheckMobiletIdAndCarListSuccess)
        await store.receive(.onCheckLocationPermissionSuccess)
        await store.receive(.onInactiveTicket)
    }
}

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
                if getParkingDataSucceeds {
                    return
                } else {
                    throw NSError(domain: "Test", code: 1)
                }
            },
            checkMobiletIdAndCarList: {
                if mobiletIdExists {
                    return
                } else {
                    throw CarPlayError.mobiletNotFound
                }
            },
            checkLocationPermissions: {
                locationEnabled ? .enabled : .disabled
            },
            getActiveTicket: {
                hasActiveTicket ? CarPlayParkingsTicketListItem.fixtureDefault : nil
            },
            getLocation: {
                if getLocationThrows {
                    throw NSError(domain: "Test", code: 2)
                } else {
                    return .mock
                }
            }
        )
    }
}

extension MKMapItem {
    static var mock: MKMapItem {
        MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
    }
}
