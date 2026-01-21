@testable import BehavioralBiometric
import Behex
import ComposableArchitecture
import XCTest

@MainActor
final class BehavioralBiometricAgreementsReducerTests: XCTestCase {
    func test_onAppear_loadsAgreementsSuccessfully() async {
        let agreements = [makeAgreement(id: "1", textConsentId: "1", mandatory: true)]
        let network = BehavioralBiometricNetworkServiceProviderMock()
        network.getAgreementsResult = .success(agreements)

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State()
        ) {
            BehavioralBiometricAgreementsReducer(
                networkService: network,
                statusStorage: BehavioralBiometricStatusStoreMock(),
                dashboardRefresher: BehavioralBiometricDashboardRefresherMock(),
                behex: BehavioralBiometricBehexMock()
            )
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.onDidLoadAgreements) {
            $0.isLoading = false
            $0.agreements = agreements
        }
    }

    func test_primaryButtonTap_withMissingMandatoryAgreements_setsUnselectedIds() async {
        let agreements = [
            makeAgreement(id: "A", textConsentId: "A", mandatory: true),
            makeAgreement(id: "B", textConsentId: "B", mandatory: false),
        ]
        let network = BehavioralBiometricNetworkServiceProviderMock()
        network.getAgreementsResult = .success(agreements)

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State(
                agreements: agreements,
                checkedAgreemntsIndexes: [1]
            )
        ) {
            BehavioralBiometricAgreementsReducer(
                networkService: BehavioralBiometricNetworkServiceProviderMock(),
                statusStorage: BehavioralBiometricStatusStoreMock(),
                dashboardRefresher: BehavioralBiometricDashboardRefresherMock(),
                behex: BehavioralBiometricBehexMock()
            )
        }

        await store.send(.onPrimaryButtonTap)

        await store.receive(\.onValidationMandatoryAgreementsResult, ["A"]) {
            $0.unselectedMandatoryAgreementsIds = ["A"]
        }
    }

    func test_primaryButtonTap_allMandatorySelected_opensMPinBottomSheet() async {
        let agreements = [
            makeAgreement(id: "A", textConsentId: "A", mandatory: true),
        ]

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State(
                agreements: agreements,
                checkedAgreemntsIndexes: [0]
            )
        ) {
            BehavioralBiometricAgreementsReducer(
                networkService: BehavioralBiometricNetworkServiceProviderMock(),
                statusStorage: BehavioralBiometricStatusStoreMock(),
                dashboardRefresher: BehavioralBiometricDashboardRefresherMock(),
                behex: BehavioralBiometricBehexMock()
            )
        }

        await store.send(.onPrimaryButtonTap)

        await store.receive(\.onValidationMandatoryAgreementsResult, []) {
            $0.unselectedMandatoryAgreementsIds = []
            $0.destination = .mPinBottomSheet
        }
    }

    func test_onReceiveMPin_enablesBehavioralBiometricSuccessfully() async {
        let network = BehavioralBiometricNetworkServiceProviderMock()
        network.getAgreementsResult = .success([])

        let statusStorage = BehavioralBiometricStatusStoreMock()
        let dashboardRefresher = BehavioralBiometricDashboardRefresherMock()

        let agreement = makeAgreement(id: "A", textConsentId: "A", mandatory: true)
        let pin = IKOUIPinMock()

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State(
                agreements: [agreement],
                checkedAgreemntsIndexes: [0]
            )
        ) {
            BehavioralBiometricAgreementsReducer(
                networkService: network,
                statusStorage: statusStorage,
                dashboardRefresher: dashboardRefresher,
                behex: BehavioralBiometricBehexMock()
            )
        }

        await store.send(.onReceiveMPin(pin)) {
            $0.isLoading = true
        }

        await store.receive(\.didEnableBehavioralBiometric) {
            $0.isLoading = false
            $0.destination = .enabledBehavioralBiometricSuccess
        }

        XCTAssertTrue(statusStorage.isEnabled)
        XCTAssertTrue(dashboardRefresher.didRefresh)
    }

    func test_onError_setsDestinationError() async {
        let network = BehavioralBiometricNetworkServiceProviderMock()
        network.getAgreementsResult = .failure(BehavioralBiometricError.timeout)

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State()
        ) {
            BehavioralBiometricAgreementsReducer(
                networkService: network,
                statusStorage: BehavioralBiometricStatusStoreMock(),
                dashboardRefresher: BehavioralBiometricDashboardRefresherMock(),
                behex: BehavioralBiometricBehexMock()
            )
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.onError, BehavioralBiometricError.timeout) {
            $0.isLoading = false
            $0.destination = .error(.timeout)
        }
    }

    // MARK: - Helpers

    private func makeAgreement(
        id: String,
        textConsentId: String,
        mandatory: Bool
    ) -> BehavioralBiometricAgreement {
        BehavioralBiometricAgreement(
            id: id,
            textConsentId: textConsentId,
            consentType: "test",
            textShort: "",
            textFull: "",
            isMandatory: mandatory
        )
    }
}
