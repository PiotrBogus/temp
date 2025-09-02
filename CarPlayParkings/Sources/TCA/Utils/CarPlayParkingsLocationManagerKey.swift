import CoreLocation
import Dependencies
import DependenciesMacros

@DependencyClient
struct CarPlayParkingsLocationManagerKey: DependencyKey {
    static let liveValue = CarPlayParkingsLocationManager(locationManager: CLLocationManager())
}

extension DependencyValues {
    var carPlayParkingsLocationManager: CarPlayParkingsLocationManager {
        get { self[CarPlayParkingsLocationManagerKey.self] }
        set { self[CarPlayParkingsLocationManagerKey.self] = newValue }
    }
}
