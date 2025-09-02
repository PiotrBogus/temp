import Dependencies
import DependenciesMacros

@DependencyClient
struct CarPlayConfirmParkingReducerClient: DependencyKey {
    var authorizeParking: (CarPlayParkingsPreauthResponse) async throws -> Void
    @Dependency(\.carPlayResourceProvider) var resourceProvider

    static let liveValue: CarPlayConfirmParkingReducerClient = {
        @Dependency(\.carPlayParkingsNetworkService) var networkService

        return CarPlayConfirmParkingReducerClient(
            authorizeParking: { preauthResponse in
                try await withCheckedThrowingContinuation { continuation in
                    networkService.authorizeParking(preauthResponse: preauthResponse) { result in
                        switch result {
                        case .success:
                            continuation.resume(returning: ())
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        )
    }()
}

extension DependencyValues {
    var confirmParkingReducerClient: CarPlayConfirmParkingReducerClient {
        get { self[CarPlayConfirmParkingReducerClient.self] }
        set { self[CarPlayConfirmParkingReducerClient.self] = newValue }
    }
}
