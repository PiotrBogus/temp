import XCTest
import ComposableArchitecture
import MapKit
@testable import YourModuleName

final class CarPlayEntryPointReducerTests: XCTestCase {

    // MARK: - Mocks
    struct MockClient {
        static func make(
            checkRequirementsResult: String? = nil,
            getParkingDataSucceeds: Bool = true,
            mobiletIdExists: Bool = true,
            hasActiveTicket: Bool = false,
            locationEnabled: Bool = true
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
                    MKMapItem()
                }
            )
        }
    }

    // MARK: - Test onAppear with successful flow
    func testOnAppear_SuccessfulFlow() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }
        )

        withDependencies {
            $0.entryPointReducerClient = MockClient.make()
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock()
        } operation: {
            await store.send(.onAppear) {
                $0.templateState = .loading("loading")
            }
        }

        await store.receive(.onCheckRequirementsSuccess)
        await store.receive(.onLoadParkingDataSuccess)
        await store.receive(.onCheckMobiletIdAndCarListSuccess)
        await store.receive(.onCheckLocationPermissionSuccess)
        await store.receive(.onInactiveTicket)
    }

    // MARK: - Test onAppear with checkRequirements error
    func testOnAppear_CheckRequirementsError() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }
        )

        withDependencies {
            $0.entryPointReducerClient = MockClient.make(checkRequirementsResult: "Requirements failed")
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock(alertButtonTryAgainText: "Try Again")
        } operation: {
            await store.send(.onAppear) {
                $0.templateState = .loading("loading")
            }
        }

        await store.receive(.onCheckRequirementsError("Requirements failed")) {
            $0.templateState = .error(
                .init(
                    type: .checkRequirementsError,
                    title: "Requirements failed",
                    description: nil,
                    buttonTitle: "Try Again"
                )
            )
        }
    }

    // MARK: - Test getActiveTicket flow
    func testOnActiveTicketFlow() async {
        let store = TestStore(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: { CarPlayEntryPointReducer() }
        )

        withDependencies {
            $0.entryPointReducerClient = MockClient.make(hasActiveTicket: true)
            $0.carPlayResourceProvider = CarPlayParkingsResourcesMock()
        } operation: {
            await store.send(.onAppear)
        }

        await store.receive(.onCheckRequirementsSuccess)
        await store.receive(.onLoadParkingDataSuccess)
        await store.receive(.onCheckMobiletIdAndCarListSuccess)
        await store.receive(.onCheckLocationPermissionSuccess)
        await store.receive(.onActiveTicket(CarPlayParkingsTicketListItem.fixtureDefault, MKMapItem()))
    }
}
