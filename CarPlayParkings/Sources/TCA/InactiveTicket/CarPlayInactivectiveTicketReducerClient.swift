import CarPlay
import Dependencies
import DependenciesMacros

@DependencyClient
struct CarPlayInactivectiveTicketReducerClient: DependencyKey {
    var getCityListByGps: () async throws -> Void
    var getLastUsedParkings: () async throws -> Void
    var gatherData: () throws -> CarPlayInactiveParkingTicketTemplateModel
    var getSubareaHint: (CPPointOfInterest) async -> String?

    @Dependency(\.carPlayResourceProvider) var resourceProvider

    static let liveValue: CarPlayInactivectiveTicketReducerClient = {
        @Dependency(\.carPlayContext) var context
        @Dependency(\.carPlayParkingsNetworkService) var networkService

        return CarPlayInactivectiveTicketReducerClient(
            getCityListByGps: {
                guard let carLocation = context.carLocation else { return }
                return try await withCheckedThrowingContinuation { contiunation in
                    networkService.getCitiListWithTarrifsByGps(location: .init(location: carLocation)) { result in
                        switch result {
                        case .success(let list):
                            context.cityListWithTarrifsByGps = list
                            contiunation.resume()
                        case .failure(let error):
                            contiunation.resume(throwing: error)
                        }
                    }
                }
            },
            getLastUsedParkings: {
                return try await withCheckedThrowingContinuation { contiunation in
                    networkService.getLastUsedParkings { result in
                        switch result {
                        case .success(let lastUsedParkings):
                            context.lastUsedParkings = lastUsedParkings
                            contiunation.resume()
                        case .failure(let error):
                            contiunation.resume(throwing: error)
                        }
                    }
                }
            },
            gatherData: {
                guard let location = context.carLocation,
                      let cities = context.cityListWithTarrifsByGps,
                      let lastUsedParkings = context.lastUsedParkings else {
                    throw CarPlayError.missingData
                }
                return CarPlayInactiveParkingTicketTemplateModel(
                    cities: cities,
                    lastUsedParkings: lastUsedParkings,
                    carLocation: location
                )
            },
            getSubareaHint: { poi in
                return await withCheckedContinuation { continuation in
                context.selectedCity = context.cityListWithTarrifsByGps?.first(where: { city in
                    city.location.rawLocation == poi.location
                })
                guard let carLocation = context.carLocation,
                      let selectedCity = context.selectedCity,
                      selectedCity.canLocateSubareaWithGps else {
                    return continuation.resume(returning: nil)
                }

                let location = CarPlayParkingsLocation(location: carLocation)
                let params = CarPlayParkingsFindSubareaByGpsParams(
                    extCityId: selectedCity.extCityId,
                    latitude: location.latitude,
                    longitude: location.longitude
                )

                    networkService.findParkingSubareaByGps(params: params) { result in
                        switch result {
                        case .success(let subareaHint):
                            return continuation.resume(returning: subareaHint)
                        case .failure:
                            return continuation.resume(returning: nil)
                        }
                    }
                }
            }
        )
    }()
}

extension DependencyValues {
    var inactiveTicketReducerClient: CarPlayInactivectiveTicketReducerClient {
        get { self[CarPlayInactivectiveTicketReducerClient.self] }
        set { self[CarPlayInactivectiveTicketReducerClient.self] = newValue }
    }
}
