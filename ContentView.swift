import ComposableArchitecture
import MapKit

extension CarPlayEntryPointReducer.Action: Equatable {
    public static func == (lhs: CarPlayEntryPointReducer.Action, rhs: CarPlayEntryPointReducer.Action) -> Bool {
        switch (lhs, rhs) {
        case (.onAppear, .onAppear),
             (.refresh, .refresh),
             (.onCheckRequirementsSuccess, .onCheckRequirementsSuccess),
             (.onLoadParkingDataSuccess, .onLoadParkingDataSuccess),
             (.onCheckMobiletIdAndCarListSuccess, .onCheckMobiletIdAndCarListSuccess),
             (.onCheckLocationPermissionSuccess, .onCheckLocationPermissionSuccess),
             (.onCheckLocationPermissionError, .onCheckLocationPermissionError),
             (.onInactiveTicket, .onInactiveTicket):
            return true

        case let (.onErrorButtonTap(a), .onErrorButtonTap(b)):
            return a == b

        case let (.onCheckRequirementsError(a), .onCheckRequirementsError(b)),
             let (.onLoadParkingDataError(errorMessage: a), .onLoadParkingDataError(errorMessage: b)):
            return a == b

        case let (.onActiveTicket(ticket1, _), .onActiveTicket(ticket2, _)):
            // Porównujemy tylko ticket, ignorujemy MKMapItem dla testów
            return ticket1 == ticket2

        case let (.destination(lhsDest), .destination(rhsDest)):
            // Porównujemy tylko enum cases, nie stan wewnątrz destination
            return lhsDest == rhsDest

        default:
            return false
        }
    }
}
