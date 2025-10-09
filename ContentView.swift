import XCTest
import ComposableArchitecture
import MapKit
@testable import YourModuleName // ← zamień na właściwy moduł

@MainActor
final class CarPlayActiveTicketReducerTests: XCTestCase {

    func test_OnAppear_StartsTimer_AndStopsAfterValidTo() async {
        let clock = TestClock()
        let now = Date()
        let validTo = now.addingTimeInterval(2).millisecondsSinceEpoch

        let activeTicket = CarPlayParkingsTicketListItem.mock(validToTimestamp: validTo)
        let overview = CarPlayParkingsActiveTicketOverviewModel.mock(timeIsUp: false)

        let store = TestStore(
            initialState: CarPlayActiveTicketReducer.State(
                activeTicket: activeTicket,
                ticket: overview,
                location: .init(),
                isTimerRunning: false
            )
        ) {
            CarPlayActiveTicketReducer()
        } withDependencies: {
            $0.continuousClock = clock
            $0.activeTicketReducerClient.stopTicket = { _ in }
            $0.activeTicketReducerClient.resourceProvider.alertButtonTryAgainText = "Try again"
            $0.carPlayParkingsErrorParser.getMessage = { _ in "Error" }
        }

        await store.send(.onAppear) {
            $0.isTimerRunning = true
        }

        await clock.advance(by: .seconds(1))
        await store.receive(.tick)

        await clock.advance(by: .seconds(1))
        await store.receive(.tick)
        await store.receive(.onTicketExpired)
        await store.receive(.stopTimer) {
            $0.isTimerRunning = false
        }
    }

    func test_OnStopTicket_SuccessFlow() async {
        let activeTicket = CarPlayParkingsTicketListItem.mock()
        let overview = CarPlayParkingsActiveTicketOverviewModel.mock()

        let store = TestStore(
            initialState: CarPlayActiveTicketReducer.State(
                activeTicket: activeTicket,
                ticket: overview,
                location: .init(),
                isTimerRunning: true
            )
        ) {
            CarPlayActiveTicketReducer()
        } withDependencies: {
            $0.activeTicketReducerClient.stopTicket = { _ in } // success
            $0.activeTicketReducerClient.resourceProvider.alertButtonTryAgainText = "Try again"
            $0.carPlayParkingsErrorParser.getMessage = { _ in "Error" }
        }

        await store.send(.onStopTicket) {
            $0.templateState = .stopTicket
        }

        await store.receive(.stopTimer) {
            $0.isTimerRunning = false
        }
        await store.receive(.onStopTicketSuccess) {
            $0.templateState = .entryPoint
        }
    }

    func test_OnStopTicket_FailureFlow() async {
        enum TestError: Error { case test }
        let activeTicket = CarPlayParkingsTicketListItem.mock()
        let overview = CarPlayParkingsActiveTicketOverviewModel.mock()

        let store = TestStore(
            initialState: CarPlayActiveTicketReducer.State(
                activeTicket: activeTicket,
                ticket: overview,
                location: .init(),
                isTimerRunning: false
            )
        ) {
            CarPlayActiveTicketReducer()
        } withDependencies: {
            $0.activeTicketReducerClient.stopTicket = { _ in throw TestError.test }
            $0.carPlayParkingsErrorParser.getMessage = { _ in "Błąd zatrzymania" }
            $0.activeTicketReducerClient.resourceProvider.alertButtonTryAgainText = "Spróbuj ponownie"
        }

        await store.send(.onStopTicket) {
            $0.templateState = .stopTicket
        }

        await store.receive(.onStopTicketFail("Błąd zatrzymania")) {
            $0.templateState = .error(.init(
                type: .stopParkingError,
                title: "Błąd zatrzymania",
                description: nil,
                buttonTitle: "Spróbuj ponownie"
            ))
        }
    }

    func test_OnTryAgain_RepeatsStopFlow() async {
        let activeTicket = CarPlayParkingsTicketListItem.mock()
        let overview = CarPlayParkingsActiveTicketOverviewModel.mock()

        let store = TestStore(
            initialState: CarPlayActiveTicketReducer.State(
                activeTicket: activeTicket,
                ticket: overview,
                location: .init(),
                isTimerRunning: false
            )
        ) {
            CarPlayActiveTicketReducer()
        } withDependencies: {
            $0.activeTicketReducerClient.stopTicket = { _ in }
            $0.activeTicketReducerClient.resourceProvider.alertButtonTryAgainText = "Try again"
            $0.carPlayParkingsErrorParser.getMessage = { _ in "Error" }
        }

        await store.send(.onTryAgain) {
            $0.templateState = .stopTicket
        }

        await store.receive(.stopTimer) {
            $0.isTimerRunning = false
        }
        await store.receive(.onStopTicketSuccess) {
            $0.templateState = .entryPoint
        }
    }
}
