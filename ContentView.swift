// BehavioralBiometricAgreementsReducerTests.swift
import XCTest
import ComposableArchitecture
@testable import YourAppModule // <- Zmień na moduł, w którym znajduje się reducer

// MARK: - Test helpers / Mocks

fileprivate struct TestError: Error, Equatable {}

fileprivate final class MockStatusStorage: BehavioralBiometricStatusStoring {
    private(set) var lastValue: Bool?
    func changeBehavioralBiometricStatus(isEnabled: Bool) {
        lastValue = isEnabled
    }
}

fileprivate struct MockNetworkService: BehavioralBiometricNetworkServiceProviding {
    var getAgreementsResult: Result<[BehavioralBiometricAgreement], Error>
    var enableResult: Result<Void, Error>

    func getBehavioralBiometricAgreements() async throws -> [BehavioralBiometricAgreement] {
        switch getAgreementsResult {
        case let .success(value): return value
        case let .failure(error): throw error
        }
    }

    func changeBehavioralBiometricStatus(isEnabled: Bool, mPin: IKOUIPin, agreements: [BehavioralBiometricAgreement]) async throws {
        switch enableResult {
        case .success: return
        case let .failure(error): throw error
        }
    }
}

// Convenience builder for agreements used repeatedly in tests
fileprivate func makeAgreement(id: String, mandatory: Bool) -> BehavioralBiometricAgreement {
    // If BehavioralBiometricAgreement has more fields in your project, adapt accordingly.
    BehavioralBiometricAgreement(id: id, isMandatory: mandatory)
}

// If IKOUIPin isn't accessible in tests, you can create a minimal shim in test target.
// But prefer using actual IKOUIPin from your app. Here we assume initializer `IKOUIPin(pin:)` exists.

final class BehavioralBiometricAgreementsReducerTests: XCTestCase {

    // MARK: - Load agreements success
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

    // MARK: - Load agreements failure
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

    // MARK: - onCheckAgreementsChanged simple state update
    func test_onCheckAgreementsChanged_updatesIndexes() async {
        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State(),
            reducer: BehavioralBiometricAgreementsReducer()
        )

        await store.send(.onCheckAgreementsChanged([0, 2])) {
            $0.checkedAgreemntsIndexes = [0, 2]
        }
    }

    // MARK: - validate mandatory returns missing ids
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

    // MARK: - validate mandatory all selected navigates to mPin
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

    // MARK: - enable behavioral biometric success
    func test_onReceiveMPin_enableBehavioralBiometricSuccess_setsDestinationAndStatus() async {
        let agreements = [ makeAgreement(id: "A", mandatory: false) ]
        let network = MockNetworkService(getAgreementsResult: .success(agreements), enableResult: .success(()))
        let status = MockStatusStorage()

        let store = TestStore(
            initialState: .init(agreements: agreements, checkedAgreemntsIndexes: [0]),
            reducer: BehavioralBiometricAgreementsReducer(networkService: network, statusStorage: status)
        )

        // Use real IKOUIPin from project. Here we assume `IKOUIPin(pin:)` initializer exists.
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

    // MARK: - enable behavioral biometric failure
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

    // MARK: - onMoreInformationTap sets destination
    func test_onMoreInformationTap_setsDestinationMoreInfo() async {
        let store = TestStore(initialState: .init(), reducer: BehavioralBiometricAgreementsReducer())

        await store.send(.onMoreInformationTap) {
            $0.destination = .moreInfo
        }
    }

    // MARK: - onResetNavigation clears destination
    func test_onResetNavigation_clearsDestination() async {
        var state = BehavioralBiometricAgreementsReducer.State()
        state.destination = .moreInfo

        let store = TestStore(initialState: state, reducer: BehavioralBiometricAgreementsReducer())

        await store.send(.onResetNavigation) {
            $0.destination = nil
        }
    }

    // MARK: - onAgreementsUpdated sets flag
    func test_onAgreementsUpdated_setsDidUpdateAgreements() async {
        let store = TestStore(initialState: .init(), reducer: BehavioralBiometricAgreementsReducer())
        await store.send(.onAgreementsUpdated) {
            $0.didUpdateAgreements = true
        }
    }

    // MARK: - onTryAgain when errorType == .agreements triggers reload
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

    // MARK: - onTryAgain when errorType == .enableBehavioralBiometric navigates to mPin
    func test_onTryAgain_afterEnableError_navigatesToMPin() async {
        var state = BehavioralBiometricAgreementsReducer.State()
        state.errorType = .enableBehavioralBiometric

        let store = TestStore(initialState: state, reducer: BehavioralBiometricAgreementsReducer())

        await store.send(.onTryAgain) {
            $0.destination = .mPinBottomSheet
        }
    }

    // MARK: - onError sets errorType and destination .error
    func test_onError_setsDestinationError() async {
        let store = TestStore(initialState: .init(), reducer: BehavioralBiometricAgreementsReducer())
        await store.send(.onError(.agreements)) {
            $0.isLoading = false
            $0.errorType = .agreements
            $0.destination = .error
        }
    }
}
