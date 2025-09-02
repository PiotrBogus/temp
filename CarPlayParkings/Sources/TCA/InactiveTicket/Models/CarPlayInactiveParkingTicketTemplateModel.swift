import Foundation
import MapKit

struct CarPlayInactiveParkingTicketTemplateModel: Sendable, Equatable {
    let cities: [CarPlayParkingsCity]
    let lastUsedParkings: [CarPlayParkingsTicketListItem]
    let carLocation: MKMapItem
}
