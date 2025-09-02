import Foundation

@objc
public final class CarPlayParkingsCity: NSObject, Sendable {
    let name: String
    let extCityId: String
    let location: CarPlayParkingsLocation
    let distance: String
    let tarrifs: [CarPlayParkingsTarrifListItem]
    let canLocateSubareaWithGps: Bool

    public init(
        name: String,
        extCityId: String,
        location: CarPlayParkingsLocation,
        distance: String,
        tarrifs: [CarPlayParkingsTarrifListItem],
        canLocateSubareaWithGps: Bool
    ) {
        self.name = name
        self.extCityId = extCityId
        self.location = location
        self.distance = distance
        self.tarrifs = tarrifs
        self.canLocateSubareaWithGps = canLocateSubareaWithGps
    }
}
