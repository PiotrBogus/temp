import Assembly
import Dependencies
import DependenciesMacros
import IKOCommon
import SwinjectAutoregistration

@DependencyClient
struct BehavioralBiometricAgreementsReducerClient: DependencyKey, Sendable {
    var loadAgreements: @Sendable () async throws -> [BehavioralBiometricAgreement]
    var enableBehavioralBiometric: @Sendable (IKOUIPin) async throws -> Void

    static let liveValue: BehavioralBiometricAgreementsReducerClient = {
        let networkService: BehavioralBiometricNetworkServiceProviding = IKOAssembler.resolver~>

        return BehavioralBiometricAgreementsReducerClient(
            loadAgreements: {
                try await networkService.getBehavioralBiometricAgreements()
            },
            enableBehavioralBiometric { mPin in
                try await networkService.changeBehavioralBiometricStatus(isEnabled: true, mPin: mPin)
            }
        )
    }()
}
extension DependencyValues {
    var behavioralBiometricAgreementsReducerClient: BehavioralBiometricAgreementsReducerClient {
        get { self[BehavioralBiometricAgreementsReducerClient.self] }
        set { self[BehavioralBiometricAgreementsReducerClient.self] = newValue }
    }
}
