import Foundation
import MapKit

public struct CarPlayParkingsLocation: Sendable {
    private enum Constants {
        static let coordinateFormat = "%.6f"
    }

    public let rawLocation: MKMapItem

    public init(location: MKMapItem) {
        rawLocation = location
    }

    public var latitude: String { String(format: Constants.coordinateFormat, rawLocation.placemark.coordinate.latitude) }
    public var longitude: String { String(format: Constants.coordinateFormat, rawLocation.placemark.coordinate.longitude) }
}
