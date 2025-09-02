import Foundation

@objc
public final class CarPlayParkingsCarParkingData: NSObject {
    let mobiletId: String
    let carList: [CarPlayParkingsCarListItem]?
    let activeParkingTicket: CarPlayParkingsTicketListItem?
    let hasActiveTicket: Bool
    let accounts: [CarPlayParkingsAccount]?

    @objc
    public init(mobiletId: String,
                carList: [CarPlayParkingsCarListItem]?,
                activeParkingTicket: CarPlayParkingsTicketListItem?,
                hasActiveTicket: Bool,
                accounts: [CarPlayParkingsAccount]?) {
        self.mobiletId = mobiletId
        self.carList = carList
        self.activeParkingTicket = activeParkingTicket
        self.hasActiveTicket = hasActiveTicket
        self.accounts = accounts
    }
}
