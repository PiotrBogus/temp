import Foundation
import MapKit

final class CarPlayParkingsContext {
    var parkingData: CarPlayParkingsCarParkingData?
    var carLocation: MKMapItem?
    var boughtTicket: CarPlayParkingsTicketListItem?
    var cityListWithTarrifsByGps: [CarPlayParkingsCity]?
    var selectedCity: CarPlayParkingsCity?
    var lastUsedParkings: [CarPlayParkingsTicketListItem]?
}
