import Foundation

@objc
public protocol CarPlayParkingsTariffWithSubareaProviding {
    var tariffId: Int64 { get }
    var extendedTariffId: String { get }
    var subareaId: Int64 { get }
    var extendedSubareaId: String { get }
    var endTime: CarPlayParkingsSubareaTime? { get }
    var allDay: Bool { get }
}
