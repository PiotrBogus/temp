import Dependencies
import DependenciesMacros
import MapKit

@DependencyClient
struct CarPlayEntryPointReducerClient: DependencyKey {
    var checkRequirements: @Sendable () -> String?
    var getParkingData: @Sendable () async throws -> Void
    var checkMobiletIdAndCarList: @Sendable () throws -> Void
    var checkLocationPermissions: @Sendable () async -> CarPlayLocationPermission = { return .disabled }
    var getActiveTicket: @Sendable () -> CarPlayParkingsTicketListItem? = { return nil }
    var getLocation: @Sendable () throws -> MKMapItem

    @Dependency(\.carPlayResourceProvider) var resourceProvider

    static let liveValue: CarPlayEntryPointReducerClient = {
        @Dependency(\.carPlayParkingsNetworkService) var networkService
        @Dependency(\.carPlayRequirementsProvider) var requirementsProvider
        @Dependency(\.carPlayContext) var context
        @Dependency(\.carPlayParkingsLocationManager) var locationManager

        return CarPlayEntryPointReducerClient(
            checkRequirements: {
                return requirementsProvider.requirements.firstFailedMessage()
            },
            getParkingData: {
                try await withCheckedThrowingContinuation { continuation in
                    networkService.getParkingData { result in
                        switch result {
                        case let .success(data):
                            context.parkingData = data
                            continuation.resume()
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            },
            checkMobiletIdAndCarList: {
                    if context.parkingData?.mobiletId == nil || context.parkingData?.carList?.isEmpty ?? false {
                        throw CarPlayError.mobiletNotFound
                    } else {
                        return
                    }
            },
            checkLocationPermissions: {
                if locationManager.isLocationEnabled() {
                    return await withCheckedContinuation { continuation in
                        locationManager.requestLocation { location in
                            context.carLocation = location
                            continuation.resume(returning: .enabled)
                        }
                    }
                } else {
                    return .disabled
                }
            },
            getActiveTicket: {
                if context.parkingData?.hasActiveTicket == true {
                    return context.parkingData?.activeParkingTicket
                } else {
                    return nil
                }
            },
            getLocation: {
                guard let location = context.carLocation else {
                    throw CarPlayError.missingData
                }
                return location
            }
        )
    }()
}

extension DependencyValues {
    var entryPointReducerClient: CarPlayEntryPointReducerClient {
        get { self[CarPlayEntryPointReducerClient.self] }
        set { self[CarPlayEntryPointReducerClient.self] = newValue }
    }
}
