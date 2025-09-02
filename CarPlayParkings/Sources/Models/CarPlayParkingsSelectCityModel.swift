import Foundation
import MapKit

final class CarPlayParkingsSelectCityModel {
    let title: String
    let cities: [CarPlayParkingsCityModel]

    init(cities: [CarPlayParkingsCity], resourceProvider: CarPlayParkingsResourceProviding) {
        self.title = resourceProvider.selectCityTitleText
        self.cities = cities.compactMap({ city in
            CarPlayParkingsCityModel(title: city.name, subtitle: city.distance, location: city.location.rawLocation)
        })
    }
}

final class CarPlayParkingsCityModel {
    let title: String
    let subtitle: String
    let location: MKMapItem

    init(title: String, subtitle: String, location: MKMapItem) {
        self.title = title
        self.subtitle = subtitle
        self.location = location
    }
}
