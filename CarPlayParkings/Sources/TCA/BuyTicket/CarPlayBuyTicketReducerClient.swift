import Dependencies
import DependenciesMacros

@DependencyClient
struct CarPlayBuyTicketReducerClient: DependencyKey {
    @Dependency(\.carPlayResourceProvider) var resourceProvider
    var loadData: (_ subareaHint: String?) throws -> CarPlayParkingsNewParkingFormModel
    var loadAccounts: () throws -> [CarPlayParkingsAccount]
    var loadSelectedCity: () throws -> CarPlayParkingsCity
    var loadCars: () throws -> [CarPlayParkingsCarListItem]
    var createAuthSession: () async throws -> Void
    var preauthorizeParking: (CarPlayParkingsNewParkingFormModel) async throws -> CarPlayParkingsPreauthResponse

    static let liveValue: CarPlayBuyTicketReducerClient = {
        @Dependency(\.carPlayResourceProvider) var resourceProvider
        @Dependency(\.carPlayParkingsNetworkService) var networkService
        @Dependency(\.carPlayRequirementsProvider) var requirementsProvider
        @Dependency(\.carPlayContext) var context
        @Dependency(\.carPlayParkingsLocationManager) var locationManager

        return CarPlayBuyTicketReducerClient(
            loadData: { subareaHint in
                guard let selectedCity = context.selectedCity,
                      let carList = context.parkingData?.carList,
                      let accounts = context.parkingData?.accounts else {
                    throw CarPlayError.missingData
                }

                return CarPlayParkingsNewParkingFormModel(
                    city: selectedCity,
                    subareaHint: subareaHint,
                    cars: carList,
                    accounts: accounts,
                    resourceProvider: resourceProvider,
                    timeOptionsResourceProvider: resourceProvider
                )
            },
            loadAccounts: {
                guard let accounts = context.parkingData?.accounts else {
                    throw CarPlayError.missingData
                }
                return accounts
            },
            loadSelectedCity: {
                guard let city = context.selectedCity else {
                    throw CarPlayError.missingData
                }
                return city
            },
            loadCars: {
                guard let cars = context.parkingData?.carList else {
                    throw CarPlayError.missingData
                }
                return cars
            },
            createAuthSession: {
                try await withCheckedThrowingContinuation { continuation in
                    guard !requirementsProvider.requirements.isLoggedIn else { return }
                    networkService.authLessLogin { result in
                        switch result {
                        case .success(()):
                            continuation.resume(returning: ())
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            },
            preauthorizeParking: { model in
                guard let selectedCar = model.selectedCar,
                      let selectedAccount = model.selectedAccount,
                      let selectedTimeOption = model.selectedTimeOption,
                      let tariffWithSubarea: CarPlayParkingsTariffWithSubareaProviding =
                        model.selectedTicket ?? model.selectedSubarea else {
                    throw CarPlayError.missingData
                }

                let startTime = Int64(Date.now.timeIntervalSince1970 * 1000)
                let endTime = selectedTimeOption.calculateEndTime(subarea: tariffWithSubarea)
                let preauthParams = CarPlayParkingsPreauthParams(
                    selectedCar: selectedCar,
                    selectedAccount: selectedAccount,
                    selectedTariffWithSubarea: tariffWithSubarea,
                    selectedTimeOption: selectedTimeOption,
                    startTimeInMillis: startTime,
                    endTimeInMillis: endTime
                )

                return try await withCheckedThrowingContinuation { continuation in
                    networkService.preauthorizeParking(params: preauthParams) { result in
                        switch result {
                        case let .success(response):
                            continuation.resume(returning: response)
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        )
    }()
}

extension DependencyValues {
    var buyTicketReducerClient: CarPlayBuyTicketReducerClient {
        get { self[CarPlayBuyTicketReducerClient.self] }
        set { self[CarPlayBuyTicketReducerClient.self] = newValue }
    }
}
