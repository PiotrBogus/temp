import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct CarPlayParkingsErrorParser: DependencyKey {
    var getMessage: (_ error: Error) -> String = { _ in return "" }

    static let liveValue: CarPlayParkingsErrorParser = {
        @Dependency(\.carPlayResourceProvider) var resourceProvider

        return CarPlayParkingsErrorParser(
            getMessage: { error in
                var message: String = resourceProvider.unknownErrorText
                guard let castedError = error as? CarPlayParkingsError else { return message }
                switch castedError {
                case .requestError(let errorMessage):
                    if let errorMessage, !errorMessage.isEmpty {
                        message = errorMessage
                    }
                }
                return message
            }
        )
    }()
}

extension DependencyValues {
    var carPlayParkingsErrorParser: CarPlayParkingsErrorParser {
        get { self[CarPlayParkingsErrorParser.self] }
        set { self[CarPlayParkingsErrorParser.self] = newValue }
    }
}
