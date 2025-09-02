import Assembly
import Dependencies
import DependenciesMacros
import ParkingPlaces
import SwinjectAutoregistration

struct CarPlayParkingsNetworkServiceKey: DependencyKey {
    static var liveValue: CarPlayParkingsNetworkServiceProviding {
        IKOAssembler.resolver~>
    }
}

extension DependencyValues {
    var carPlayParkingsNetworkService: CarPlayParkingsNetworkServiceProviding {
        get { self[CarPlayParkingsNetworkServiceKey.self] }
        set { self[CarPlayParkingsNetworkServiceKey.self] = newValue }
    }
}
