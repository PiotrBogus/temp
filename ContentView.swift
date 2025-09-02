import XCTest
import ComposableArchitecture
@testable import YourModuleName

@MainActor
final class CarPlayAccountSelectionReducerTests: XCTestCase {
    func testOnAccountSelection_SendsDelegateWithAccount() async {
        let store = TestStore(
            initialState: CarPlayAccountSelectionReducer.State(),
            reducer: { CarPlayAccountSelectionReducer() }
        )

        await store.send(.onAccountSelection(.fixtureDefault))
        await store.receive(.delegate(.dismissAccountSelection(.fixtureDefault)))
    }

    func testDidPop_SendsDelegateWithNil() async {
        let store = TestStore(
            initialState: CarPlayAccountSelectionReducer.State(),
            reducer: { CarPlayAccountSelectionReducer() }
        )

        await store.send(.didPop)
        await store.receive(.delegate(.dismissAccountSelection(nil)))
    }

    func testDelegate_DoesNotMutateState() async {
        let state = CarPlayAccountSelectionReducer.State(
            templateState: .didAppear,
            accounts: [.fixtureDefault, .fixtureSecondary]
        )

        let store = TestStore(
            initialState: state,
            reducer: { CarPlayAccountSelectionReducer() }
        )

        await store.send(.delegate(.dismissAccountSelection(.fixtureSecondary)))
        // brak zmian w stanie i brak dalszych efektów
    }
}


@testable import YourModuleName

extension CarPlayParkingsAccount {
    static let fixtureDefault = CarPlayParkingsAccount(
        "001",
        name: "Default Account",
        digest: "digest-001",
        isDefault: true
    )

    static let fixtureSecondary = CarPlayParkingsAccount(
        "002",
        name: "Secondary Account",
        digest: "digest-002",
        isDefault: false
    )

    static func fixture(
        number: String = UUID().uuidString,
        name: String = "Fixture Account",
        digest: String = UUID().uuidString,
        isDefault: Bool = false
    ) -> CarPlayParkingsAccount {
        CarPlayParkingsAccount(number, name: name, digest: digest, isDefault: isDefault)
    }
}
