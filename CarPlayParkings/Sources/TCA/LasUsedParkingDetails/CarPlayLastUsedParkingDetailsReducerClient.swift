import Dependencies
import DependenciesMacros

@DependencyClient
struct CarPlayLastUsedParkingDetailsReducerClient: DependencyKey {
    var getParkingTimeOptions: (Int64, Int64) async throws -> [CarPlayParkingsTariffTimeOption]
    var loadAccounts: () throws -> [CarPlayParkingsAccount]
    var loadCars: () throws -> [CarPlayParkingsCarListItem]
    @Dependency(\.carPlayResourceProvider) var resourceProvider

    static let liveValue: CarPlayLastUsedParkingDetailsReducerClient = {
        @Dependency(\.carPlayParkingsNetworkService) var networkService
        @Dependency(\.carPlayContext) var context

        return CarPlayLastUsedParkingDetailsReducerClient(
            getParkingTimeOptions: { locationId, tariffId in
                try await withCheckedThrowingContinuation { continuation in
                    networkService.getParkingTimeOptions(locationId: locationId, tariffId: tariffId, ) { result in
                        switch result {
                        case let .success(options):
                            continuation.resume(returning: options)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            },
            loadAccounts: {
                guard let accounts = context.parkingData?.accounts else {
                    throw CarPlayError.missingData
                }
                return accounts
            },
            loadCars: {
                guard let cars = context.parkingData?.carList else {
                    throw CarPlayError.missingData
                }
                return cars
            },
        )
    }()
}

extension DependencyValues {
    var lastUsedParkingDetailsReducerClient: CarPlayLastUsedParkingDetailsReducerClient {
        get { self[CarPlayLastUsedParkingDetailsReducerClient.self] }
        set { self[CarPlayLastUsedParkingDetailsReducerClient.self] = newValue }
    }
}
