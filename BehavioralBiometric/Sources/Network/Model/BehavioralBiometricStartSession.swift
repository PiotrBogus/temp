import Foundation

public struct BehavioralBiometricStartSession {
    public let enabled: Bool
    public let cssId: String?

    public init(enabled: Bool, cssId: String?) {
        self.enabled = enabled
        self.cssId = cssId
    }
}
