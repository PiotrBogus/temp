import XCTest
import ComposableArchitecture
@testable import CarPlayParkings

final class CarPlayBuyTicketReducerTests: XCTestCase {

    func test_onAppear_loadsData_success() async {
        let store = TestStore(
            initialState: CarPlayBuyTicketReducer.State(),
            reducer: { CarPlayBuyTicketReducer() },
            withDependencies: {
                $0.buyTicketReducerClient = .success
            }
        )

        await store.send(.onAppear)

        await store.receive(\.didLoadData) { state, action in
            state.data = action.0
            state.templateState = .didAppear
        }
    }

    func test_onAppear_loadsData_failure_fallsBackToRefresh() async {
        let store = TestStore(
            initialState: CarPlayBuyTicketReducer.State(),
            reducer: { CarPlayBuyTicketReducer() },
            withDependencies: {
                $0.buyTicketReducerClient = .failure
            }
        )

        await store.send(.onAppear)

        await store.receive(\.refresh) { state, _ in
            state.templateState = .loading(
                store.dependencies.buyTicketReducerClient.resourceProvider.loadingSplashText
            )
        }
    }

    func test_onNextButtonTap_validationFailure() async {
        let model = CarPlayParkingsNewParkingFormModel.fixture()
        // "zerujemy" wymagane pola żeby wymusić błędy
        model.selectedCar = nil
        model.selectedAccount = nil
        model.selectedTimeOption = nil
        model.selectedSubarea = nil

        let store = TestStore(
            initialState: CarPlayBuyTicketReducer.State(data: model),
            reducer: { CarPlayBuyTicketReducer() },
            withDependencies: {
                $0.buyTicketReducerClient = .success
            }
        )

        await store.send(.onNextButtonTap)
        await store.receive(\.onValidationFormError) { state, action in
            state.templateState = .validationError(_, action.0)
        }
    }

    func test_onNextButtonTap_validationSuccess_andPreauthSuccess() async {
        let model = CarPlayParkingsNewParkingFormModel.fixture()
        // w fixture mamy wypełnione wszystkie wymagane pola

        let store = TestStore(
            initialState: CarPlayBuyTicketReducer.State(data: model),
            reducer: { CarPlayBuyTicketReducer() },
            withDependencies: {
                $0.buyTicketReducerClient = .success
            }
        )

        await store.send(.onNextButtonTap)

        await store.receive(\.onValidationFormSuccess) { state, _ in
            state.templateState = .preauthNewParkingProcessingSplash
        }

        await store.receive(\.didPreauthorizeParking) { state, action in
            state.destination = .confirmParking(
                CarPlayConfirmParkingReducer.State(preauthResponse: action.0, model: model)
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
            }
        )

        await store.send(.onNextButtonTap)

        await store.receive(\.onValidationFormSuccess) { state, _ in
            state.templateState = .preauthNewParkingProcessingSplash
        }

        await store.receive(\.error) { state, action in
            state.templateState = .error(.init(
                type: .preauthorizeError,
                title: store.dependencies.carPlayParkingsErrorParser.getMessage(action.0),
                description: nil,
                buttonTitle: store.dependencies.buyTicketReducerClient.resourceProvider.alertButtonTryAgainText
            ))
        }
    }
}
