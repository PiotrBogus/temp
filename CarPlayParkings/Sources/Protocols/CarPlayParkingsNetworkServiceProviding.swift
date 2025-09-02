public enum CarPlayParkingsError: Error {
    case requestError(String?)
}

public protocol CarPlayParkingsNetworkServiceProviding {
    var accountBlockedHandler: (() -> Void)? { get set }

    func authLessLogin(_ completion: @escaping (Result<Void, CarPlayParkingsError>) -> Void)
    func getParkingData(_ completion: @escaping (Result<CarPlayParkingsCarParkingData, CarPlayParkingsError>) -> Void)
    func stopBooking(ticket: CarPlayParkingsTicketListItem, completion: @escaping (Result<CarPlayParkingsTicketListItem, CarPlayParkingsError>) -> Void)
    func getCitiListWithTarrifsByGps(location: CarPlayParkingsLocation, completion: @escaping (Result<[CarPlayParkingsCity], CarPlayParkingsError>) -> Void)
    func preauthorizeParking(params: CarPlayParkingsPreauthParams, completion: @escaping (Result<CarPlayParkingsPreauthResponse, CarPlayParkingsError>) -> Void)
    func authorizeParking(preauthResponse: CarPlayParkingsPreauthResponse, completion: @escaping (Result<Void, CarPlayParkingsError>) -> Void)
    func getLastUsedParkings(completion: @escaping (Result<[CarPlayParkingsTicketListItem], CarPlayParkingsError>) -> Void)
    func getParkingTimeOptions(locationId: Int64, tariffId: Int64, completion: @escaping (Result<[CarPlayParkingsTariffTimeOption], CarPlayParkingsError>) -> Void)
    func findParkingSubareaByGps(params: CarPlayParkingsFindSubareaByGpsParams, completion: @escaping (Result<String, CarPlayParkingsError>) -> Void)
    func setServerConfigIfNeeded()
}
