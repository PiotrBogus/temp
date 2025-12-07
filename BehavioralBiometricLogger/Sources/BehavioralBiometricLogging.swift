import Foundation

public protocol BehavioralBiometricLogging: Sendable {
    func configure() async throws
    func setCssid(id: String) async
    func startSendingEvents() async
    func stopSendingEvents() async
}
