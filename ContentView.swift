@testable import Authorization
import Dependencies
import Testing

@Suite("Logout operations performer tests")
struct LogoutOperationsPerformerTests {
    let sut = LogoutOperationsPerformer.liveValue

    @Test("When invoking perform, it should do all necessary operations")
    // swiftlint:disable:next function_body_length
    func perform() {
        let storeAnalyticsEventsInvokedCount = LockIsolated(0)
        let blikResetInvokedCount = LockIsolated(0)
        let openBankingResetInvokedCount = LockIsolated(0)
        let mobileAuthorizationResetInvokedCount = LockIsolated(0)
        let closedAdvertsOfferDataInvokedCount = LockIsolated(0)
        let offersSessionDataClearInvokedCount = LockIsolated(0)
        let clearContextInvokedCount = LockIsolated(0)
        let flushUserContextInvokedCount = LockIsolated(0)
        let talk2IKOConfigurationResetInvokedCount = LockIsolated(0)
        let cancelAllRequestsInvokedCount = LockIsolated(0)
        let sessionLoginDateClearInvokedCount = LockIsolated(0)
        let increaseLogoutCounterInvokedCount = LockIsolated(0)
        let clearStoredSessionIdentifierInvokedCount = LockIsolated(0)
        let loadEnablersForDefaultContextInvokedCount = LockIsolated(0)

        withDependencies {
            $0[AnalyticsStore.self].storeAnalyticsEvents = {
                storeAnalyticsEventsInvokedCount.withValue { $0 += 1 }
            }
            $0[BlikResetService.self].reset = {
                blikResetInvokedCount.withValue { $0 += 1 }
            }
            $0[OpenBankingResetService.self].reset = {
                openBankingResetInvokedCount.withValue { $0 += 1 }
            }
            $0[MobileAuthorizationResetService.self].reset = {
                mobileAuthorizationResetInvokedCount.withValue { $0 += 1 }
            }
            $0[ContextClearer.self].clear = {
                clearContextInvokedCount.withValue { $0 += 1 }
            }
            $0[ClosedAdvertsOfferDataClearer.self].clear = {
                closedAdvertsOfferDataInvokedCount.withValue { $0 += 1 }
            }
            $0[OffersSessionDataClearer.self].clear = {
                offersSessionDataClearInvokedCount.withValue { $0 += 1 }
            }
            $0[UserContextFlusher.self].flush = {
                flushUserContextInvokedCount.withValue { $0 += 1 }
            }
            $0[Talk2IKOConfigurationResetService.self].reset = {
                talk2IKOConfigurationResetInvokedCount.withValue { $0 += 1 }
            }
            $0[NetworkRequestCanceller.self].cancelAll = {
                cancelAllRequestsInvokedCount.withValue { $0 += 1 }
            }
            $0[SessionLoginDateClearer.self].clear = {
                sessionLoginDateClearInvokedCount.withValue { $0 += 1 }
            }
            $0[GreetingsLogoutCounter.self].increase = {
                increaseLogoutCounterInvokedCount.withValue { $0 += 1 }
            }
            $0[AnalyticsStore.self].clearStoredSessionIdentifier = {
                clearStoredSessionIdentifierInvokedCount.withValue { $0 += 1 }
            }
            $0[EnablersLoader.self].loadEnablersForDefaultContext = {
                loadEnablersForDefaultContextInvokedCount.withValue { $0 += 1 }
            }
        } operation: {
            await sut.perform()
        }

        #expect(storeAnalyticsEventsInvokedCount.value == 1, "It should store all analytics events")
        #expect(blikResetInvokedCount.value == 1, "It should reset BLIK Manager")
        #expect(openBankingResetInvokedCount.value == 1, "It should reset Open Banking status tracker")
        #expect(mobileAuthorizationResetInvokedCount.value == 1, "It should reset Mobile Authorization transaction manager")
        #expect(clearContextInvokedCount.value == 1, "It should clear current context (MSP, Individual or child)")
        #expect(closedAdvertsOfferDataInvokedCount.value == 1, "It should clear adverts session data")
        #expect(offersSessionDataClearInvokedCount.value == 1, "It should clear offers session data")
        #expect(flushUserContextInvokedCount.value == 1, "It should flush current user context")
        #expect(talk2IKOConfigurationResetInvokedCount.value == 1, "It should reset Talk 2 IKO configuration")
        #expect(cancelAllRequestsInvokedCount.value == 1, "It should cancel all requests")
        #expect(sessionLoginDateClearInvokedCount.value == 1, "It should clear last login date")
        #expect(increaseLogoutCounterInvokedCount.value == 1, "It should increase logout counter")
        #expect(clearStoredSessionIdentifierInvokedCount.value == 1, "It should clear stored session identifier")
        #expect(loadEnablersForDefaultContextInvokedCount.value == 1, "It should load enablers for default context")
    }
}


import Dependencies
import DependenciesMacros
/// Performs all logout related operations (e.g. clearing caches, context, etc).
@DependencyClient
public struct LogoutOperationsPerformer: Sendable {
    /// Perform all operations.
    public var perform: @Sendable () async -> Void
}

extension LogoutOperationsPerformer: TestDependencyKey {
    public static let testValue = LogoutOperationsPerformer(perform: { })
}

extension LogoutOperationsPerformer: DependencyKey {
    public static let liveValue = LogoutOperationsPerformer {
        @Dependency(\.behavioralBiometricClearer) var behavioralBiometricClearer
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

        await behavioralBiometricClearer.clear()
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
