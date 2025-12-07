import Foundation

@objc
public protocol BehavioralBiometricTouchLogging: NSObjectProtocol {
    func startClearingTouchCoordinates() async
    func sstopClearingTouchCoordinates() async
}
