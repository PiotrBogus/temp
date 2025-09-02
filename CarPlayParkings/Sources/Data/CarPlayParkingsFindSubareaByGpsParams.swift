import Foundation

public struct CarPlayParkingsFindSubareaByGpsParams {
    public let extCityId: String
    public let latitude: String
    public let longitude: String

    init(
        extCityId: String,
        latitude: String,
        longitude: String
    ) {
        self.extCityId = extCityId
        self.latitude = latitude
        self.longitude = longitude
    }
}
