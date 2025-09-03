@testable import CarPlayParkings

extension CarPlayBuyTicketReducerClient {
    /// Zawsze zwraca poprawne dane i preautoryzację
    static let success = CarPlayBuyTicketReducerClient(
        loadData: { _ in .fixture() },
        loadAccounts: { [.fixture()] },
        loadSelectedCity: { .fixture() },
        loadCars: { [.fixture()] },
        createAuthSession: { },
        preauthorizeParking: { _ in .fixture }
    )

    /// Zawsze rzuca błąd `CarPlayError.missingData`
    static let failure = CarPlayBuyTicketReducerClient(
        loadData: { _ in throw CarPlayError.missingData },
        loadAccounts: { throw CarPlayError.missingData },
        loadSelectedCity: { throw CarPlayError.missingData },
        loadCars: { throw CarPlayError.missingData },
        createAuthSession: { throw CarPlayError.missingData },
        preauthorizeParking: { _ in throw CarPlayError.missingData }
    )

    /// Wersja do sterowania ręcznie (np. w konkretnym teście)
    static func custom(
        loadData: @escaping (_ subareaHint: String?) throws -> CarPlayParkingsNewParkingFormModel = { _ in .fixture() },
        loadAccounts: @escaping () throws -> [CarPlayParkingsAccount] = { [.fixture()] },
        loadSelectedCity: @escaping () throws -> CarPlayParkingsCity = { .fixture() },
        loadCars: @escaping () throws -> [CarPlayParkingsCarListItem] = { [.fixture()] },
        createAuthSession: @escaping () async throws -> Void = { },
        preauthorizeParking: @escaping (CarPlayParkingsNewParkingFormModel) async throws -> CarPlayParkingsPreauthResponse = { _ in .fixture }
    ) -> CarPlayBuyTicketReducerClient {
        CarPlayBuyTicketReducerClient(
            loadData: loadData,
            loadAccounts: loadAccounts,
            loadSelectedCity: loadSelectedCity,
            loadCars: loadCars,
            createAuthSession: createAuthSession,
            preauthorizeParking: preauthorizeParking
        )
    }
}
