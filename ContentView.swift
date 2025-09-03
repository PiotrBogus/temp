import XCTest
import ComposableArchitecture
@testable import CarPlayParkings

@MainActor
final class CarPlayConfirmParkingReducerTests: XCTestCase {

    func testOnConfirm_AuthorizeSuccess() async {
        let store = TestStore(
            initialState: CarPlayConfirmParkingReducer.State(
                preauthResponse: .fixture,
                model: .fixture
            ),
            reducer: { CarPlayConfirmParkingReducer() },
            withDependencies: {
                $0.confirmParkingReducerClient = .init(
                    authorizeParking: { _ in }, // success, nic nie rzuca
                    resourceProvider: CarPlayParkingsResourcesMock(
                        alertButtonTryAgainText: "Retry"
                    )
                )
                $0.carPlayParkingsErrorParser = .init(
                    getMessage: { _ in "Parsed error" }
                )
            }
        )

        await store.send(.onConfirm) {
            $0.templateState = .loading
        }

        await store.receive(.onAuthorizeParkingSuccess) {
            $0.templateState = .entryPoint
        }
    }

    func testOnConfirm_AuthorizeFailure() async {
        struct DummyError: Error {}

        let store = TestStore(
            initialState: CarPlayConfirmParkingReducer.State(
                preauthResponse: .fixture,
                model: .fixture
            ),
            reducer: { CarPlayConfirmParkingReducer() },
            withDependencies: {
                $0.confirmParkingReducerClient = .init(
                    authorizeParking: { _ in throw DummyError() },
                    resourceProvider: CarPlayParkingsResourcesMock(
                        alertButtonTryAgainText: "Retry"
                    )
                )
                $0.carPlayParkingsErrorParser = .init(
                    getMessage: { _ in "Parsed error" }
                )
            }
        )

        await store.send(.onConfirm) {
            $0.templateState = .loading
        }

        await store.receive(.onAuthorizeParkingFailure(DummyError())) {
            $0.templateState = .error(
                .init(
                    type: .authorizeParkingError,
                    title: "Parsed error",
                    description: nil,
                    buttonTitle: "Retry"
                )
            )
        }
    }

    func testOnTryAgain_TriggersAuthorize() async {
        let store = TestStore(
            initialState: CarPlayConfirmParkingReducer.State(
                preauthResponse: .fixture,
                model: .fixture
            ),
            reducer: { CarPlayConfirmParkingReducer() },
            withDependencies: {
                $0.confirmParkingReducerClient = .init(
                    authorizeParking: { _ in }, // succeeds
                    resourceProvider: CarPlayParkingsResourcesMock(
                        alertButtonTryAgainText: "Retry"
                    )
                )
                $0.carPlayParkingsErrorParser = .testValue
            }
        )

        await store.send(.onTryAgain) {
            $0.templateState = .loading
        }

        await store.receive(.onAuthorizeParkingSuccess) {
            $0.templateState = .entryPoint
        }
    }
}
