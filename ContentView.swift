@testable import CarPlayParkings

// MARK: - Test Mocks for CarPlayConfirmParkingReducerClient
extension CarPlayConfirmParkingReducerClient {
    static let success = CarPlayConfirmParkingReducerClient(
        authorizeParking: { _ in }, // nie rzuca -> sukces
        resourceProvider: CarPlayParkingsResourcesMock(
            alertButtonTryAgainText: "Retry"
        )
    )

    static func failure(_ error: Error = NSError(domain: "Test", code: 1)) -> CarPlayConfirmParkingReducerClient {
        CarPlayConfirmParkingReducerClient(
            authorizeParking: { _ in throw error },
            resourceProvider: CarPlayParkingsResourcesMock(
                alertButtonTryAgainText: "Retry"
            )
        )
    }
}
