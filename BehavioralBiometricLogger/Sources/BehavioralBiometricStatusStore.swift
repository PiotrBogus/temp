import Assembly
import Foundation
@preconcurrency import PersistentStorage
import SwinjectAutoregistration

public protocol BehavioralBiometricStatusStoring: Sendable {
    func isBehavioralBiometricEnabledByUser() -> Bool
    func changeBehavioralBiometricStatus(isEnabled: Bool)
}

public final class BehavioralBiometricStatusStore: BehavioralBiometricStatusStoring {
    private struct Constants {
        static let isBehavioralBiometricEnabledByUserKey = UserDefaultsKey<Bool>(rawValue: "isBehavioralBiometricEnabledByUserKey")
    }

    private let storage: UserDefaultsStorage

    public init(storage: UserDefaultsStorage = IKOAssembler.resolver~>) {
        self.storage = storage
    }

    public func isBehavioralBiometricEnabledByUser() -> Bool {
        storage.value(for: Constants.isBehavioralBiometricEnabledByUserKey) ?? false
    }

    public func changeBehavioralBiometricStatus(isEnabled: Bool) {
        storage.set(isEnabled, for: Constants.isBehavioralBiometricEnabledByUserKey)
    }
}
