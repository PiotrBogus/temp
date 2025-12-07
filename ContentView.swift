import BehavioralBiometricLogger
@testable import BehavioralBiometric
import ComposableArchitecture
import UIComponents
import XCTest

// MARK: - Helper types

private struct TestError: Error, Equatable {}

private final class BehavioralBiometricStatusStoreMock: BehavioralBiometricStatusStoring {
    nonisolated(unsafe) var isEnabled: Bool = false

    func isBehavioralBiometricEnabledByUser() -> Bool {
        isEnabled
    }

    func changeBehavioralBiometricStatus(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}

private struct BehavioralBiometricNetworkServiceProviderMock: BehavioralBiometricNetworkServiceProviding {

    var getAgreementsResult: Result<[BehavioralBiometricAgreement], Error> = .success([])
    func getBehavioralBiometricAgreements() async throws -> [BehavioralBiometricAgreement] {
        try getAgreementsResult.get()
    }

    var changeBehavioralBiometricStatusResult: Result<Void, Error> = .success(())
    func changeBehavioralBiometricStatus(isEnabled: Bool, mPin: any IKOCommon.IKOUIPin, agreements: [BehavioralBiometricAgreement]?) async throws {
        try changeBehavioralBiometricStatusResult.get()
    }

    var getBehavioralBiometricStateResult: Result<BehavioralBiometricState, Error> = .success(.init(enabled: true))
    func getBehavioralBiometricState() async throws -> BehavioralBiometricState {
        try getBehavioralBiometricStateResult.get()
    }

    var startSessionResult: Result<BehavioralBiometricStartSession, Error> = .success(.init(sessionId: "id"))
    func startSession(latitude: String?, longitude: String?) async throws -> BehavioralBiometricStartSession {
        try startSessionResult.get()
    }

    var stopSessionResult: Result<Void, Error> = .success(())
    func stopSession() async throws {
        try stopSessionResult.get()
    }
}

// MARK: - Small helper
private func makeAgreement(id: String, mandatory: Bool) -> BehavioralBiometricAgreement {
    BehavioralBiometricAgreement(id: id, isMandatory: mandatory)
}

// MARK: - Tests

final class BehavioralBiometricAgreementsReducerTests: XCTestCase {

    func test_onAppear_loadAgreementsSuccess() async {
        let agreements = [
            makeAgreement(id: "1", mandatory: false),
            makeAgreement(id: "2", mandatory: true)
        ]

        var network = BehavioralBiometricNetworkServiceProviderMock()
        network.getAgreementsResult = .success(agreements)

        let status = BehavioralBiometricStatusStoreMock()

        let store = TestStore(
            initialState: .init(),
            reducer: {
                BehavioralBiometricAgreementsReducer(
                    networkService: network,
                    statusStorage: status
                )
            }
        )

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(.onDidLoadAgreements(agreements)) {
            $0.agreements = agreements
            $0.isLoading = false
        }
    }

    func test_onAppear_loadAgreementsFailure_setsError() async {
        var network = BehavioralBiometricNetworkServiceProviderMock()
        network.getAgreementsResult = .failure(TestError())

        let status = BehavioralBiometricStatusStoreMock()

        let store = TestStore(
            initialState: .init(),
            reducer: {
                BehavioralBiometricAgreementsReducer(
                    networkService: network,
                    statusStorage: status
                )
            }
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
            initialState: .init(),
            reducer: { BehavioralBiometricAgreementsReducer() }
        )

        await store.send(.onCheckAgreementsChanged([0, 2])) {
            $0.checkedAgreemntsIndexes = [0, 2]
        }
    }

    func test_onPrimaryButtonTap_validatesMissingMandatory() async {
        let agreements = [
            makeAgreement(id: "A", mandatory: true),
            makeAgreement(id: "B", mandatory: false),
            makeAgreement(id: "C", mandatory: true)
        ]

        let store = TestStore(
            initialState: .init(agreements: agreements),
            reducer: { BehavioralBiometricAgreementsReducer() }
        )

        await store.send(.onPrimaryButtonTap)

        await store.receive(.onValidationMandatoryAgreementsResult(["A", "C"])) {
            $0.unselectedMandatoryAgreementsIds = ["A", "C"]
        }
    }

    func test_onPrimaryButtonTap_allMandatorySelected_navigatesToMPin() async {
        let agreements = [
            makeAgreement(id: "A", mandatory: true),
            makeAgreement(id: "B", mandatory: false)
        ]

        let store = TestStore(
            initialState: .init(
                agreements: agreements,
                checkedAgreemntsIndexes: [0]
            ),
            reducer: { BehavioralBiometricAgreementsReducer() }
        )

        await store.send(.onPrimaryButtonTap)
        await store.receive(.onValidationMandatoryAgreementsResult([])) {
            $0.unselectedMandatoryAgreementsIds = []
            $0.destination = .mPinBottomSheet
        }
    }

    func test_onReceiveMPin_enableSuccess() async {
        let agreements = [ makeAgreement(id: "A", mandatory: false) ]

        var network = BehavioralBiometricNetworkServiceProviderMock()
        network.getAgreementsResult = .success(agreements)
        network.changeBehavioralBiometricStatusResult = .success(())

        let status = BehavioralBiometricStatusStoreMock()

        let store = TestStore(
            initialState: .init(
                agreements: agreements,
                checkedAgreemntsIndexes: [0]
            ),
            reducer: {
                BehavioralBiometricAgreementsReducer(
                    networkService: network,
                    statusStorage: status
                )
            }
        )

        let pin = IKOUIPin(pin: "1234")

        await store.send(.onReceiveMPin(pin)) {
            $0.isLoading = true
        }

        await store.receive(.didEnableBehavioralBiometric) {
            $0.isLoading = false
            $0.destination = .enabledBehavioralBiometricSuccess
        }

        XCTAssertEqual(status.isEnabled, true)
    }

    func test_onReceiveMPin_enableFailure_setsError() async {
        let agreements = [ makeAgreement(id: "A", mandatory: false) ]

        var network = BehavioralBiometricNetworkServiceProviderMock()
        network.changeBehavioralBiometricStatusResult = .failure(TestError())

        let status = BehavioralBiometricStatusStoreMock()

        let store = TestStore(
            initialState: .init(
                agreements: agreements,
                checkedAgreemntsIndexes: [0]
            ),
            reducer: {
                BehavioralBiometricAgreementsReducer(
                    networkService: network,
                    statusStorage: status
                )
            }
        )

        let pin = IKOUIPin(pin: "1234")

        await store.send(.onReceiveMPin(pin)) {
            $0.isLoading = true
        }

        await store.receive(.onError(.enableBehavioralBiometric)) {
            $0.isLoading = false
            $0.errorType = .enableBehavioralBiometric
            $0.destination = .error
        }
    }

    func test_onMoreInformationTap_setsDestination() async {
        let store = TestStore(
            initialState: .init(),
            reducer: { BehavioralBiometricAgreementsReducer() }
        )

        await store.send(.onMoreInformationTap) {
            $0.destination = .moreInfo
        }
    }

    func test_onResetNavigation_clearsDestination() async {
        let store = TestStore(
            initialState: .init(destination: .moreInfo),
            reducer: { BehavioralBiometricAgreementsReducer() }
        )

        await store.send(.onResetNavigation) {
            $0.destination = nil
        }
    }

    func test_onAgreementsUpdated_setsFlag() async {
        let store = TestStore(
            initialState: .init(),
            reducer: { BehavioralBiometricAgreementsReducer() }
        )

        await store.send(.onAgreementsUpdated) {
            $0.didUpdateAgreements = true
        }
    }

    func test_onTryAgain_afterAgreementsError_reloads() async {
        let agreements = [ makeAgreement(id: "A", mandatory: false) ]

        var network = BehavioralBiometricNetworkServiceProviderMock()
        network.getAgreementsResult = .success(agreements)

        let status = BehavioralBiometricStatusStoreMock()

        let store = TestStore(
            initialState: .init(errorType: .agreements),
            reducer: {
                BehavioralBiometricAgreementsReducer(
                    networkService: network,
                    statusStorage: status
                )
            }
        )

        await store.send(.onTryAgain) {
            $0.isLoading = true
        }

        await store.receive(.onDidLoadAgreements(agreements)) {
            $0.isLoading = false
            $0.agreements = agreements
        }
    }

    func test_onTryAgain_enableError_navigatesToMPin() async {
        let store = TestStore(
            initialState: .init(errorType: .enableBehavioralBiometric),
            reducer: { BehavioralBiometricAgreementsReducer() }
        )

        await store.send(.onTryAgain) {
            $0.destination = .mPinBottomSheet
        }
    }

    func test_onError_setsProperState() async {
        let store = TestStore(
            initialState: .init(),
            reducer: { BehavioralBiometricAgreementsReducer() }
        )

        await store.send(.onError(.agreements)) {
            $0.isLoading = false
            $0.errorType = .agreements
            $0.destination = .error
        }
    }
}
