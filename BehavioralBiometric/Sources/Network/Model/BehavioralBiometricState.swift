import Foundation

public struct BehavioralBiometricState: Sendable, Equatable {
    let errorDescription: String?
    public let enabled: Bool
    let agreementsDate: String
    let agreements: [BehavioralBiometricAgreement]

    public init(
        errorDescription: String? = nil,
        enabled: Bool,
        agreementsDate: String,
        agreements: [BehavioralBiometricAgreement]
    ) {
        self.errorDescription = errorDescription
        self.enabled = enabled
        self.agreementsDate = agreementsDate
        self.agreements = agreements
    }
}
