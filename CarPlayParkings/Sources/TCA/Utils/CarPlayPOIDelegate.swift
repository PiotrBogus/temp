import CarPlay
import Foundation

final class CarPlayPOIDelegate: NSObject, CPPointOfInterestTemplateDelegate {
    @Published var selectedPOI: CPPointOfInterest?

    func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion) {}

    func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didSelectPointOfInterest pointOfInterest: CPPointOfInterest) {
        selectedPOI = pointOfInterest
    }
}
