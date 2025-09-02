import Foundation

enum CarPlayEntryPointFeatureErrorType: Sendable {
    case locationPermissionError
    case checkMobiletIdAndCarListError
    case loadParkingDataError
    case checkRequirementsError
}
