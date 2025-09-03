@testable import CarPlayParkings

// MARK: - CarPlayParkingsNewParkingFormModel Fixture
extension CarPlayParkingsNewParkingFormModel {
    static func fixture(
        cars: [CarPlayParkingsCarListItem] = [],
        accounts: [CarPlayParkingsAccount] = []
    ) -> CarPlayParkingsNewParkingFormModel {
        CarPlayParkingsNewParkingFormModel(
            city: CarPlayParkingsCity(
                name: "Test City",
                tarrifs: []
            ),
            subareaHint: nil,
            cars: cars,
            accounts: accounts,
            resourceProvider: CarPlayParkingsResourcesMock(
                selectText: "Select",
                newParkingCarTitleText: "Car",
                newParkingAccountTitleText: "Account",
                newParkingTimeTypeTitleText: "Time",
                noActiveParkingSelectZoneEmptyText: "No Zones",
                parkingZoneText: "Zone"
            ),
            timeOptionsResourceProvider: CarPlayParkingsTimeOptionsResourceProviderMock()
        )
    }
}
