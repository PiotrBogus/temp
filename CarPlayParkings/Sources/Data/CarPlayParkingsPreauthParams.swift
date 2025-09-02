import Foundation

@objc
public final class CarPlayParkingsPreauthParams: NSObject {
    public let selectedCar: CarPlayParkingsCarListItem
    public let selectedAccount: CarPlayParkingsAccount
    public let selectedTariffWithSubarea: CarPlayParkingsTariffWithSubareaProviding
    public let selectedTimeOption: CarPlayParkingsTariffTimeOption
    public let startTimeInMillis: Int64
    public let endTimeInMillis: Int64

    public init(selectedCar: CarPlayParkingsCarListItem,
                selectedAccount: CarPlayParkingsAccount,
                selectedTariffWithSubarea: CarPlayParkingsTariffWithSubareaProviding,
                selectedTimeOption: CarPlayParkingsTariffTimeOption,
                startTimeInMillis: Int64,
                endTimeInMillis: Int64) {
        self.selectedCar = selectedCar
        self.selectedAccount = selectedAccount
        self.selectedTariffWithSubarea = selectedTariffWithSubarea
        self.selectedTimeOption = selectedTimeOption
        self.startTimeInMillis = startTimeInMillis
        self.endTimeInMillis = endTimeInMillis
    }
}
