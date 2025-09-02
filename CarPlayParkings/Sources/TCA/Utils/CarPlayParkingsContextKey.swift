import Dependencies
import DependenciesMacros

@DependencyClient
struct CarPlayParkingsContextKey: DependencyKey {
    static let liveValue = CarPlayParkingsContext()
}

extension DependencyValues {
    var carPlayContext: CarPlayParkingsContext {
        get { self[CarPlayParkingsContextKey.self] }
        set { self[CarPlayParkingsContextKey.self] = newValue }
    }
}
