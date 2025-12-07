import BehavioralBiometricLogger
@testable import BehavioralBiometric
import ComposableArchitecture
import UIComponents
import XCTest


private struct TestError: Error, Equatable {}

private final class BehavioralBiometricStatusStoreMock: BehavioralBiometricStatusStoring {
    nonisolated(unsafe) private var isEnabled: Bool = false

    func isBehavioralBiometricEnabledByUser() -> Bool {
        isEnabled
    }
    
    func changeBehavioralBiometricStatus(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}

private struct BehavioralBiometricNetworkServiceProviderMock: BehavioralBiometricNetworkServiceProviding {
    var getAgreementsResult: Result<[BehavioralBiometricAgreement], Error>

    func getBehavioralBiometricAgreements() async throws -> [BehavioralBiometricAgreement] {
        switch getAgreementsResult {
        case let .success(value): return value
        case let .failure(error): throw error
        }
    }

    var changeBehavioralBiometricStatusResult: Result<Void, Error>

    func changeBehavioralBiometricStatus(isEnabled: Bool, mPin: any IKOCommon.IKOUIPin, agreements: [BehavioralBiometricAgreement]?) async throws {
        switch changeBehavioralBiometricStatusResult {
        case .success: return
        case let .failure(error): throw error
        }
    }

    var getBehavioralBiometricStateResult: Result<BehavioralBiometricState, Error>

    func getBehavioralBiometricState() async throws -> BehavioralBiometricState {
        switch getBehavioralBiometricStateResult {
        case let .success(value): return value
        case let .failure(error): throw error
        }
    }

    var startSessionResult: Result<BehavioralBiometricStartSession, Error>

    func startSession(latitude: String?, longitude: String?) async throws -> BehavioralBiometricStartSession {
        switch startSessionResult {
        case let .success(value): return value
        case let .failure(error): throw error
        }
    }

    var stopSessionResult: Result<Void, Error>

    func stopSession() async throws {
        switch stopSessionResult {
        case .success: return
        case let .failure(error): throw error
        }
    }
}

final class BehavioralBiometricAgreementsReducerTests: XCTestCase {
    func test_onAppear_loadAgreementsSuccess() async {
        let agreements = [makeAgreement(id: "1", mandatory: false), makeAgreement(id: "2", mandatory: true)]

        let network = MockNetworkService(
            getAgreementsResult: .success(agreements),
            enableResult: .success(())
        )
        let status = MockStatusStorage()

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State(),
            reducer: BehavioralBiometricAgreementsReducer(networkService: network, statusStorage: status)
        )

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(.onDidLoadAgreements(agreements)) {
            $0.isLoading = false
            $0.agreements = agreements
        }
    }

    func test_onAppear_loadAgreementsFailure_setsError() async {
        let network = MockNetworkService(
            getAgreementsResult: .failure(TestError()),
            enableResult: .success(())
        )
        let status = MockStatusStorage()

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State(),
            reducer: BehavioralBiometricAgreementsReducer(networkService: network, statusStorage: status)
        )

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(.onError(.agreements)) {
            $0.isLoading = false
            $0.errorType = .agreements
            $0.destination = .error
        }
    }

    func test_onCheckAgreementsChanged_updatesIndexes() async {
        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State(),
            reducer: BehavioralBiometricAgreementsReducer()
        )

        await store.send(.onCheckAgreementsChanged([0, 2])) {
            $0.checkedAgreemntsIndexes = [0, 2]
        }
    }

    func test_onPrimaryButtonTap_validatesAndReturnsMissingMandatoryIds() async {
        let agreements = [
            makeAgreement(id: "A", mandatory: true),
            makeAgreement(id: "B", mandatory: false),
            makeAgreement(id: "C", mandatory: true)
        ]
        let store = TestStore(
            initialState: .init(agreements: agreements),
            reducer: BehavioralBiometricAgreementsReducer()
        )

        await store.send(.onPrimaryButtonTap)

        await store.receive(.onValidationMandatoryAgreementsResult(["A", "C"])) {
            $0.unselectedMandatoryAgreementsIds = ["A", "C"]
        }
    }

    func test_onPrimaryButtonTap_allMandatorySelected_navigatesToMpin() async {
        let agreements = [
            makeAgreement(id: "A", mandatory: true),
            makeAgreement(id: "B", mandatory: false)
        ]
        let store = TestStore(
            initialState: .init(agreements: agreements, checkedAgreemntsIndexes: [0]),
            reducer: BehavioralBiometricAgreementsReducer()
        )

        await store.send(.onPrimaryButtonTap)
        await store.receive(.onValidationMandatoryAgreementsResult([])) {
            $0.unselectedMandatoryAgreementsIds = []
            $0.destination = .mPinBottomSheet
        }
    }

    func test_onReceiveMPin_enableBehavioralBiometricSuccess_setsDestinationAndStatus() async {
        let agreements = [ makeAgreement(id: "A", mandatory: false) ]
        let network = MockNetworkService(getAgreementsResult: .success(agreements), enableResult: .success(()))
        let status = MockStatusStorage()

        let store = TestStore(
            initialState: .init(agreements: agreements, checkedAgreemntsIndexes: [0]),
            reducer: BehavioralBiometricAgreementsReducer(networkService: network, statusStorage: status)
        )

        let mpin = IKOUIPin(pin: "1234")

        await store.send(.onReceiveMPin(mpin)) {
            $0.isLoading = true
        }

        await store.receive(.didEnableBehavioralBiometric) {
            $0.isLoading = false
            $0.destination = .enabledBehavioralBiometricSuccess
        }

        XCTAssertEqual(status.lastValue, true)
    }

    func test_onReceiveMPin_enableBehavioralBiometricFailure_setsError() async {
        let agreements = [ makeAgreement(id: "A", mandatory: false) ]
        let network = MockNetworkService(getAgreementsResult: .success(agreements), enableResult: .failure(TestError()))
        let status = MockStatusStorage()

        let store = TestStore(
            initialState: .init(agreements: agreements, checkedAgreemntsIndexes: [0]),
            reducer: BehavioralBiometricAgreementsReducer(networkService: network, statusStorage: status)
        )

        let mpin = IKOUIPin(pin: "1234")
        await store.send(.onReceiveMPin(mpin)) {
            $0.isLoading = true
        }

        await store.receive(.onError(.enableBehavioralBiometric)) {
            $0.isLoading = false
            $0.errorType = .enableBehavioralBiometric
            $0.destination = .error
        }
    }

    func test_onMoreInformationTap_setsDestinationMoreInfo() async {
        let store = TestStore(initialState: .init(), reducer: BehavioralBiometricAgreementsReducer())

        await store.send(.onMoreInformationTap) {
            $0.destination = .moreInfo
        }
    }

    func test_onResetNavigation_clearsDestination() async {
        var state = BehavioralBiometricAgreementsReducer.State()
        state.destination = .moreInfo

        let store = TestStore(initialState: state, reducer: BehavioralBiometricAgreementsReducer())

        await store.send(.onResetNavigation) {
            $0.destination = nil
        }
    }

    func test_onAgreementsUpdated_setsDidUpdateAgreements() async {
        let store = TestStore(initialState: .init(), reducer: BehavioralBiometricAgreementsReducer())
        await store.send(.onAgreementsUpdated) {
            $0.didUpdateAgreements = true
        }
    }

    func test_onTryAgain_afterAgreementsError_reloads() async {
        let agreements = [ makeAgreement(id: "A", mandatory: false) ]
        let network = MockNetworkService(getAgreementsResult: .success(agreements), enableResult: .success(()))
        let status = MockStatusStorage()

        var state = BehavioralBiometricAgreementsReducer.State()
        state.errorType = .agreements

        let store = TestStore(initialState: state, reducer: BehavioralBiometricAgreementsReducer(networkService: network, statusStorage: status))

        await store.send(.onTryAgain) {
            $0.isLoading = true
        }

        await store.receive(.onDidLoadAgreements(agreements)) {
            $0.isLoading = false
            $0.agreements = agreements
        }
    }

    func test_onTryAgain_afterEnableError_navigatesToMPin() async {
        var state = BehavioralBiometricAgreementsReducer.State()
        state.errorType = .enableBehavioralBiometric

        let store = TestStore(initialState: state, reducer: BehavioralBiometricAgreementsReducer())

        await store.send(.onTryAgain) {
            $0.destination = .mPinBottomSheet
        }
    }

    func test_onError_setsDestinationError() async {
        let store = TestStore(initialState: .init(), reducer: BehavioralBiometricAgreementsReducer())
        await store.send(.onError(.agreements)) {
            $0.isLoading = false
            $0.errorType = .agreements
            $0.destination = .error
        }
    }
}
