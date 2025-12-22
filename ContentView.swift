import BehavioralBiometric
import Foundation
@preconcurrency import IKOCommon
import SwinjectAutoregistration

final class BehavioralBiometricNetworkServiceProvider: BehavioralBiometricNetworkServiceProviding, @unchecked Sendable {
    private let service: Service
    private let core: IKOCore
    private var partnerSessionId: String?

    init(core: IKOCore = IKOAssembler.resolver~>) {
        self.core = core
        service = Service(with: CoreNetworking(core: core))
    }

    func changeBehavioralBiometricStatus(
        isEnabled: Bool,
        mPin: IKOUIPin,
        agreements: [BehavioralBiometricAgreement]?
    ) async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let castedPin = mPin as? IKOCorePin else {
                fatalError("Expecting IKOCorePin class")
            }
            let params = IKOCoreChangeBehavioralBiometricStateParams()
            params.enabled = isEnabled
            params.mPin = castedPin
            params.agreements = agreements?.compactMap {
                let agreement = IKOCoreBehavioralBiometricApiAgreement()
                agreement.consentType = $0.consentType
                agreement.textConsentId = $0.textConsentId
                agreement.consent = true
                return agreement
            }

            let operation = self?.core.requestChangeBehavioralBiometricStateWithParams(params) {
                continuation.resume()
            }
            self?.handleError(for: operation, with: continuation)
            self?.service.makeRequest(with: operation)
        }
    }

    func getBehavioralBiometricAgreements() async throws -> [BehavioralBiometricAgreement] {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            let operation = self?.core.requestGetBehavioralBiometricAgreementsWithCompletion { response in
                guard let response else {
                    continuation.resume(throwing: BehavioralBiometricError.emptyResponse)
                    return
                }
                let agreements = response.agreements.compactMap {
                    BehavioralBiometricAgreement(
                        textConsentId: $0.textConsentId,
                        consentType: $0.consentType,
                        textShort: $0.textShort,
                        textFull: $0.textFull,
                        isMandatory: $0.mandatory
                    )
                }
                continuation.resume(returning: agreements)
            }
            self?.handleError(for: operation, with: continuation)
            self?.service.makeRequest(with: operation)
        }
    }

    func getBehavioralBiometricState() async throws -> BehavioralBiometricState {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            let operation = self?.core.requestGetBehavioralBiometricStateWithCompletion { response in
                guard let response else {
                    continuation.resume(throwing: BehavioralBiometricError.emptyResponse)
                    return
                }
                continuation.resume(returning: BehavioralBiometricState(
                    enabled: response.enabled,
                    agreementsDate: response.agreementsDate,
                    agreements: response.agreements.compactMap {
                        BehavioralBiometricAgreement(
                            textConsentId: $0.textConsentId,
                            consentType: $0.consentType,
                            textShort: $0.textShort,
                            textFull: $0.textFull,
                            isMandatory: $0.mandatory
                        )
                    }
                ))
            }
            self?.handleError(for: operation, with: continuation)
            self?.service.makeRequest(with: operation)
        }
    }

    func startSession(latitude: String?, longitude: String?) async throws -> BehavioralBiometricStartSession {
        guard partnerSessionId == nil else {
            throw BehavioralBiometricError.sessionInProgress
        }
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            let params = IKOCoreStartBehavioralBiometricSessionParams()
            params.latitude = latitude
            params.longitude = longitude

            let operation = self?.core.requestStartBehavioralBiometricSessionWithParams(params) { response in
                guard let response else {
                    continuation.resume(throwing: BehavioralBiometricError.emptyResponse)
                    return
                }
                self?.partnerSessionId = response.partnerSessionId
                continuation.resume(returning: BehavioralBiometricStartSession(
                    enabled: response.enabled,
                    cssId: response.cssId
                ))
            }
            self?.handleError(for: operation, with: continuation)
            self?.service.makeRequest(with: operation)
        }
    }

    func stopSession() async throws {
        guard let partnerSessionId else {
            throw BehavioralBiometricError(type: .missingPartnerSessionId)
        }
        try await withCheckedThrowingContinuation { [weak self] continuation in
            let params = IKOCoreStopBehavioralBiometricSessionParams()
            params.partnerSessionId = partnerSessionId
            self?.partnerSessionId = nil
            let operation = self?.core.requestStopBehavioralBiometricSessionWithParams(params) {
                continuation.resume()
            }
            self?.handleError(for: operation, with: continuation)
            self?.service.makeRequest(with: operation)
        }
    }

    private func handleError<T>(for operation: IKOCoreOperation?, with continuation: CheckedContinuation<T, BehavioralBiometricError>) {
        operation?.errorHandler = { coreError in
            let error = BehavioralBiometricError(
                type: .generalError,
                title: coreError?.errorTitle,
                description: coreError?.errorDescription
            )
            continuation.resume(throwing: error)
        }

        operation?.failHandler = { _ in
            let error = BehavioralBiometricError(
                type: .generalError
            )
            continuation.resume(throwing: error)
            return true
        }

        operation?.resultHandler.timeoutHandler = {
            let error = BehavioralBiometricError(
                type: .timeout
            )
            continuation.resume(throwing: error)
        }

        operation?.fieldErrorsHandler = { coreError in
            let error = BehavioralBiometricError(
                type: .fieldErrors,
                title: coreError?.errorTitle,
                description: coreError?.errorDescription
            )
            continuation.resume(throwing: error)
        }
    }
}


import Foundation

public struct BehavioralBiometricError: Error, Sendable, Equatable {
    let type: BehavioralBiometricErrorType
    let title: String?
    let description: String?

    public init(
        type: BehavioralBiometricErrorType,
        title: String? = nil,
        description: String? = nil
    ) {
        self.type = type
        self.title = title
        self.description = description
    }
}
