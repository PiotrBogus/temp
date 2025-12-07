import Foundation

public struct BehavioralBiometricAgreement: Sendable, Equatable, Identifiable {
    public let id: String
    let textShort: String
    let text: String
    public let isMandatory: Bool

    public init(
        id: String,
        textShort: String,
        text: String,
        isMandatory: Bool
    ) {
        self.id = id
        self.textShort = textShort
        self.text = text
        self.isMandatory = isMandatory
    }
}
