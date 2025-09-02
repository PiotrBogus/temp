import CarPlay

public enum CarPlayParkingsRequirement: CaseIterable {
    case appActive
    case featureEnabled
    case dataTransmissionOn
    case demoModeDisabled
}

public protocol CarPlayParkingsRequirementsDelegate: AnyObject {
    func requirementsChanged()
}

public protocol CarPlayParkingsRequirementsProviding {
    var isLoggedIn: Bool { get }

    func isFulfilled(_ requirement: CarPlayParkingsRequirement) -> Bool
    func failedMessage(_ requirement: CarPlayParkingsRequirement) -> String
    func firstFailedMessage() -> String?
    func registerRequirementsDelegate(_ delegate: CarPlayParkingsRequirementsDelegate)
}
