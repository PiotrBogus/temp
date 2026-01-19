import Dependencies
import DependenciesMacros
@DependencyClient
public struct SessionWiper: Sendable {
    /// Wipes all stored session data in native-core layer.
    public var wipe: @Sendable () -> Void
}

extension SessionWiper: TestDependencyKey {
    public static let testValue = SessionWiper(wipe: {})
}


/Users/jenkins/workspace/mob-ios/Projects/App/Authorization/Sources/Logout/Dependencies/SessionWiper.swift:10:1: error: (emptyBraces) Remove whitespace inside empty braces.

