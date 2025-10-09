private func startTimer(until validTo: Int64) -> Effect<Action> {
    .run { send, dependencies in
        let clock = dependencies.clock
        let validToDate = Date(timeIntervalSince1970: TimeInterval(validTo) / 1000)

        for await _ in clock.timer(interval: .seconds(1)) {
            await send(.tick)

            // Zatrzymaj timer, gdy czas upłynął
            if Date() >= validToDate {
                await send(.onTicketExpired)
                await send(.stopTimer)
                break
            }
        }
    }
    .cancellable(id: CancelID.timer, cancelInFlight: true)
}


import XCTest
import ComposableArchitecture
@testable import YourModuleName // ← Zamień na właściwy moduł

@MainActor
final class CarPlayActiveTicketReducerTests: XCTestCase {

    func testTimerStopsAfterValidTo() async {
        // 1️⃣ Przygotowanie zegara testowego
        let clock = TestClock()

        // 2️⃣ Stworzenie przykładowych danych
        let now = Date()
        let validTo = now.addingTimeInterval(3).millisecondsSinceEpoch // timer ma działać 3 sekundy

        let ticket = CarPlayParkingsActiveTicketOverviewModel.mock
        let listItem = CarPlayParkingsTicketListItem.mock

        let store = TestStore(
            initialState: CarPlayActiveTicketReducer.State(
                activeTicket: listItem,
                ticket: ticket,
                location: .init(),
                isTimerRunning: false
            )
        ) {
            CarPlayActiveTicketReducer()
        } withDependencies: {
            $0.continuousClock = clock
            $0.carPlayParkingsErrorParser.getMessage = { _ in "Error" }
            $0.activeTicketReducerClient.stopTicket = { _ in }
            $0.activeTicketReducerClient.resourceProvider.alertButtonTryAgainText = "Try again"
        }

        // 3️⃣ Uruchamiamy timer
        await store.send(.onAppear) {
            $0.isTimerRunning = true
        }

        // 4️⃣ Zegar przesuwa się o 1s → tick
        await clock.advance(by: .seconds(1))
        await store.receive(.tick)

        // 5️⃣ Kolejna sekunda → tick
        await clock.advance(by: .seconds(1))
        await store.receive(.tick)

        // 6️⃣ Kolejna sekunda (3s) → tick, a potem timer się kończy
        await clock.advance(by: .seconds(1))
        await store.receive(.tick)
        await store.receive(.onTicketExpired)
        await store.receive(.stopTimer) {
            $0.isTimerRunning = false
        }
    }
}
