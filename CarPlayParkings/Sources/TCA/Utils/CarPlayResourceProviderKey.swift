import Assembly
import Dependencies
import DependenciesMacros
import SwinjectAutoregistration

@DependencyClient
struct CarPlayResourceProviderKey: DependencyKey {
    static let liveValue: CarPlayParkingsResources = IKOAssembler.resolver~>
}

extension DependencyValues {
    var carPlayResourceProvider: CarPlayParkingsResources {
        get { self[CarPlayResourceProviderKey.self] }
        set { self[CarPlayResourceProviderKey.self] = newValue }
    }
}
