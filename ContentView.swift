import XCTest
import ComposableArchitecture
@testable import CarPlayParkings

@MainActor
final class CarPlayBuyTicketReducerTests: XCTestCase {

    func test_onAppear_loadsData_success() async {
        let store = TestStore(
            initialState: CarPlayBuyTicketReducer.State(),
            reducer: { CarPlayBuyTicketReducer() },
            withDependencies: {
                $0.buyTicketReducerClient = .success
                $0.carPlayParkingsErrorParser = .mock
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock()
            }
        )

        await store.send(.onAppear)

        await store.receive(where: { action in
            if case .effect(.didLoadData) = action { return true }
            return false
        }) {
            $0.data = .fixture()
            $0.templateState = .didAppear
        }
    }

    func test_onAppear_loadsData_failure_fallsBackToRefresh() async {
        let store = TestStore(
            initialState: CarPlayBuyTicketReducer.State(),
            reducer: { CarPlayBuyTicketReducer() },
            withDependencies: {
                $0.buyTicketReducerClient = .failure
                $0.carPlayParkingsErrorParser = .mock
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock()
            }
        )

        await store.send(.onAppear)

        await store.receive(where: { action in
            if case .refresh = action { return true }
            return false
        }) {
            $0.templateState = .loading(
                store.dependencies.buyTicketReducerClient.resourceProvider.loadingSplashText
            )
        }
    }

    func test_onNextButtonTap_validationFailure() async {
        let model = CarPlayParkingsNewParkingFormModel.fixture()
        model.selectedCar = nil
        model.selectedAccount = nil
        model.selectedTimeOption = nil
        model.selectedSubarea = nil

        let store = TestStore(
            initialState: CarPlayBuyTicketReducer.State(data: model),
            reducer: { CarPlayBuyTicketReducer() },
            withDependencies: {
                $0.buyTicketReducerClient = .success
                $0.carPlayParkingsErrorParser = .mock
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock()
            }
        )

        await store.send(.template(.onNextButtonTap))

        await store.receive(where: { action in
            if case .effect(.onValidationFormError) = action { return true }
            return false
        }) {
            $0.templateState = .validationError(.init(), [])
        }
    }

    func test_onNextButtonTap_validationSuccess_andPreauthSuccess() async {
        let model = CarPlayParkingsNewParkingFormModel.fixture()

        let store = TestStore(
            initialState: CarPlayBuyTicketReducer.State(data: model),
            reducer: { CarPlayBuyTicketReducer() },
            withDependencies: {
                $0.buyTicketReducerClient = .success
                $0.carPlayParkingsErrorParser = .mock
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock()
            }
        )

        await store.send(.template(.onNextButtonTap))

        await store.receive(where: { action in
            if case .effect(.onValidationFormSuccess) = action { return true }
            return false
        }) {
            $0.templateState = .preauthNewParkingProcessingSplash
        }

        await store.receive(where: { action in
            if case .effect(.didPreauthorizeParking) = action { return true }
            return false
        }) {
            $0.destination = .confirmParking(
                CarPlayConfirmParkingReducer.State(preauthResponse: .fixture, model: model)
            )
        }
    }

    func test_onNextButtonTap_validationSuccess_andPreauthFailure() async {
        let model = CarPlayParkingsNewParkingFormModel.fixture()

        let failingClient = CarPlayBuyTicketReducerClient.custom(
            preauthorizeParking: { _ in throw CarPlayError.missingData }
        )

        let store = TestStore(
            initialState: CarPlayBuyTicketReducer.State(data: model),
            reducer: { CarPlayBuyTicketReducer() },
            withDependencies: {
                $0.buyTicketReducerClient = failingClient
                $0.carPlayParkingsErrorParser = .mock
                $0.carPlayResourceProvider = CarPlayParkingsResourcesMock()
            }
        )

        await store.send(.template(.onNextButtonTap))

        await store.receive(where: { action in
            if case .effect(.onValidationFormError) = action { return true }
            return false
        }) {
            $0.templateState = .validationError(UUID(), [.areaNotSelected, .timeOptionNotSelected])
        }
    }
}
