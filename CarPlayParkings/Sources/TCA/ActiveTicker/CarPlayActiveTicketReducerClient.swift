import Dependencies
import DependenciesMacros

@DependencyClient
struct CarPlayActiveTicketReducerClient: DependencyKey {
    var stopTicket: (CarPlayParkingsTicketListItem) async throws -> Void
    @Dependency(\.carPlayResourceProvider) var resourceProvider

    static let liveValue: CarPlayActiveTicketReducerClient = {
        @Dependency(\.carPlayParkingsNetworkService) var networkService
        @Dependency(\.carPlayContext) var context

        return CarPlayActiveTicketReducerClient(
            stopTicket: { ticket in
                try await withCheckedThrowingContinuation { continuation in
                    networkService.stopBooking(ticket: ticket) { result in
                        switch result {
                        case let .success(ticket):
                            context.boughtTicket = ticket
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
    var activeTicketReducerClient: CarPlayActiveTicketReducerClient {
        get { self[CarPlayActiveTicketReducerClient.self] }
        set { self[CarPlayActiveTicketReducerClient.self] = newValue }
    }
}
