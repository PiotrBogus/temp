    private func handleFeatureContition() -> Bool {
        withCheckedContinuation { continuation in
            let networkServiceProvider: BehavioralBiometricNetworkServiceProvider = IKOAssembler.resolver~>
            let state = try? await networkServiceProvider.getBehavioralBiometricState()
            let isDisabled = state?.enabled == false
            continuation.resume(returning: isDisabled)
        }
    }
