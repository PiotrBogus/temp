import CoreLocation
import Foundation
import Logger
import MapKit

final class CarPlayParkingsLocationManager: NSObject, CLLocationManagerDelegate {
    var completions: [(MKMapItem?) -> Void] = []

    private let locationManager: CLLocationManager

    public init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        super.init()
        self.locationManager.delegate = self
    }

    public func requestLocation(completion: @escaping (MKMapItem?) -> Void) {
        if let location = locationManager.location {
            completion(MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate)))
        } else {
            completions.append(completion)
            locationManager.requestLocation()
        }
    }

    public func isLocationEnabled() -> Bool {
        locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for completion in completions {
            if let coordinate = locationManager.location?.coordinate {
                completion(MKMapItem(placemark: MKPlacemark(coordinate: coordinate)))
            } else {
                completion(nil)
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        for completion in completions {
            completion(nil)
        }
        IKOLogger.error(error.localizedDescription)
    }
}
