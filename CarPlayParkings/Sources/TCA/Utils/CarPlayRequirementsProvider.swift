import Assembly
import Dependencies
import DependenciesMacros
import SwinjectAutoregistration

@DependencyClient
struct CarPlayRequirementsProvider: DependencyKey {
    let requirements: CarPlayParkingsRequirementsProviding = IKOAssembler.resolver~>

    static let liveValue = CarPlayRequirementsProvider()
}

extension DependencyValues {
    var carPlayRequirementsProvider: CarPlayRequirementsProvider {
        get { self[CarPlayRequirementsProvider.self] }
        set { self[CarPlayRequirementsProvider.self] = newValue }
    }
}
