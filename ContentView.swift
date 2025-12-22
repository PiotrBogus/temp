private func handleError<T>(
    for operation: IKOCoreOperation?,
    with continuation: CheckedContinuation<T, BehavioralBiometricError>
) {
    operation?.errorHandler = { coreError in
        continuation.resume(
            throwing: .general(
                title: coreError?.errorTitle,
                description: coreError?.errorDescription
            )
        )
    }

    operation?.failHandler = { _ in
        continuation.resume(throwing: .general(title: nil, description: nil))
        return true
    }

    operation?.resultHandler.timeoutHandler = {
        continuation.resume(throwing: .timeout)
    }

    operation?.fieldErrorsHandler = { coreError in
        continuation.resume(
            throwing: .fieldErrors(
                title: coreError?.errorTitle,
                description: coreError?.errorDescription
            )
        )
    }
}




public enum BehavioralBiometricError: Error, Sendable, Equatable {

    case emptyResponse
    case sessionInProgress
    case missingPartnerSessionId

    case timeout
    case fieldErrors(title: String?, description: String?)
    case general(title: String?, description: String?)

    case unknown
}
