import Foundation

@objc
public final class CarPlayParkingsAccount: NSObject, Sendable {
    public let accountNumber: String
    public let name: String
    public let digest: String
    public let isDefault: Bool

    @objc
    public init(
        _ accountNumber: String,
        name: String,
        digest: String,
        isDefault: Bool
    ) {
        self.accountNumber = accountNumber
        self.name = name
        self.digest = digest
        self.isDefault = isDefault
    }
}
