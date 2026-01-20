import Assembly
import Dependencies
import DependenciesMacros
import SwinjectAutoregistration
/// Performs all logout related operations (e.g. clearing caches, context, etc).
@DependencyClient
public struct LogoutOperationsPerformer: Sendable {
    /// Perform all operations.
    public var perform: @Sendable () -> Void
}

extension LogoutOperationsPerformer: TestDependencyKey {
    public static let testValue = LogoutOperationsPerformer(perform: { })
}

extension LogoutOperationsPerformer: DependencyKey {
    public static let liveValue = LogoutOperationsPerformer {
        let behavioralBiometricClearer: BehavioralBiometricLogoutClearing = IKOAssembler.resolver~>
        @Dependency(AnalyticsStore.self) var analyticsStore
        @Dependency(BlikResetService.self) var blikResetService
        @Dependency(OpenBankingResetService.self) var openBankingResetService
        @Dependency(MobileAuthorizationResetService.self) var mobileAuthorizationResetService
        @Dependency(ContextClearer.self) var contextClearer
        @Dependency(ClosedAdvertsOfferDataClearer.self) var closedAdvertsOfferDataClearer
        @Dependency(OffersSessionDataClearer.self) var offersSessionDataClearer
        @Dependency(UserContextFlusher.self) var userContextFlusher
        @Dependency(Talk2IKOConfigurationResetService.self) var talk2IKOConfigurationResetService
        @Dependency(NetworkRequestCanceller.self) var networkRequestCanceller
        @Dependency(SessionLoginDateClearer.self) var sessionLoginDateClearer
        @Dependency(GreetingsLogoutCounter.self) var greetingLogoutCounter
        @Dependency(EnablersLoader.self) var enablersLoader

        behavioralBiometricClearer.clear()
        analyticsStore.storeAnalyticsEvents()
        blikResetService.reset()
        openBankingResetService.reset()
        mobileAuthorizationResetService.reset()
        contextClearer.clear()
        closedAdvertsOfferDataClearer.clear()
        offersSessionDataClearer.clear()
        userContextFlusher.flush()
        talk2IKOConfigurationResetService.reset()
        networkRequestCanceller.cancelAll()
        sessionLoginDateClearer.clear()
        greetingLogoutCounter.increase()
        analyticsStore.clearStoredSessionIdentifier()
        enablersLoader.loadEnablersForDefaultContext()
    }
}
