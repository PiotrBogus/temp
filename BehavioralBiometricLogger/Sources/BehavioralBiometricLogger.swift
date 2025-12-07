import Assembly
@preconcurrency import CrashReporting
import Foundation
@preconcurrency import IKOCommon
@preconcurrency import PWBB_SDK
import SwinjectAutoregistration

public enum BehavioralBiometricLoggerError: Error {
    case configureError
}

public actor BehavioralBiometricLogger: NSObject, BehavioralBiometricLogging, BehavioralBiometricTouchLogging {

    private var digitalFingerprints: DigitalFingerprints = .init()
    private let crashReporter: CrashReporting
    private let statusStore: BehavioralBiometricStatusStoring
    private let featuresProvider: FeaturesProviding
    nonisolated(unsafe) private var didConfigureLibrary: Bool = false
    private var chipServerUrl: String {
        "https://b-dev.awtvlnric3q.pl"
    }

    public init(
        crashReporter: CrashReporting = IKOAssembler.resolver~>,
        statusStore: BehavioralBiometricStatusStoring = IKOAssembler.resolver~>,
        featuresProvider: FeaturesProviding = IKOAssembler.resolver~>
    ) {
        self.crashReporter = crashReporter
        self.statusStore = statusStore
        self.featuresProvider = featuresProvider
        super.init()
    }

    @MainActor
    public func configure() async throws {
        guard !didConfigureLibrary,
            await featuresProvider.isEnabled(.behavioralBiometric),
              statusStore.isBehavioralBiometricEnabledByUser() else {
            throw BehavioralBiometricLoggerError.configureError
        }
        do {
            try await digitalFingerprints
                .attach(to: nil, withGlobalGestureDetector: true)
                .addChipHttpAddress(chipServerUrl)
                .initializeGatheringEvents()
                .initializeSendingEventsLazy()
                .startGatheringEvents()

            didConfigureLibrary = true
        } catch let error {
            await crashReporter.capture(
                message: "Behavioral biometric error to configure",
                additionalData: [
                    "errorMessage": error.localizedDescription
                ]
            )
            print(error.localizedDescription)
            throw BehavioralBiometricLoggerError.configureError
        }
    }

    public func setCssid(id: String) async {
        do {
            try digitalFingerprints.setCssid(id)
        } catch let error {
            crashReporter.capture(
                message: "Behavioral biometric error to set cssid",
                additionalData: [
                    "errorMessage": error.localizedDescription
                ]
            )
            print(error.localizedDescription)
        }
    }

    public func startSendingEvents() async {
        do {
            try digitalFingerprints.startSendingEvents()
        } catch let error {
            crashReporter.capture(
                message: "Behavioral biometric error to start sending events",
                additionalData: [
                    "errorMessage": error.localizedDescription
                ]
            )
            print(error.localizedDescription)
        }
    }

    public func stopSendingEvents() async {
        digitalFingerprints.stopSendingEvents()
    }

    public func startClearingTouchCoordinates() async {
        let newDigitalFingerptin = digitalFingerprints.enableClearingTouchCoordinates()
        digitalFingerprints = newDigitalFingerptin
    }

    public func sstopClearingTouchCoordinates() async {
        let newDigitalFingerptin = digitalFingerprints.disableClearingTouchCoordinates()
        digitalFingerprints = newDigitalFingerptin
    }
}
