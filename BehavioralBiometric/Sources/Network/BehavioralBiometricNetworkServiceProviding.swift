import Foundation
import IKOCommon

public protocol BehavioralBiometricNetworkServiceProviding: Sendable {
    func changeBehavioralBiometricStatus(isEnabled: Bool, mPin: IKOUIPin, agreements: [BehavioralBiometricAgreement]?) async throws
    func getBehavioralBiometricAgreements() async throws -> [BehavioralBiometricAgreement]
    func getBehavioralBiometricState() async throws -> BehavioralBiometricState
    func startSession(latitude: String?, longitude: String?) async throws -> BehavioralBiometricStartSession
    func stopSession() async throws
}
