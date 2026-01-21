import XCTest
import ComposableArchitecture
@testable import YourModuleName

final class BehavioralBiometricAgreementsReducerTests: XCTestCase {

    // MARK: - Mocks

    private final class NetworkServiceMock: BehavioralBiometricNetworkServiceProviding {
        var agreementsResult: Result<[BehavioralBiometricAgreement], Error>!
        var changeStatusCalled = false

        func getBehavioralBiometricAgreements() async throws -> [BehavioralBiometricAgreement] {
            try agreementsResult.get()
        }

        func changeBehavioralBiometricStatus(
            isEnabled: Bool,
            mPin: IKOUIPin,
            agreements: [BehavioralBiometricAgreement]?
        ) async throws {
            changeStatusCalled = true
        }
    }

    private final class StatusStorageMock: BehavioralBiometricStatusStoring {
        var isEnabled: Bool?

        func changeBehavioralBiometricStatus(isEnabled: Bool) {
            self.isEnabled = isEnabled
        }
    }

    private final class DashboardRefresherMock: BehavioralBiometricDashboardRefreshing {
        var didRefresh = false

        func refresh() {
            didRefresh = true
        }
    }

    private final class BehexMock: Behex {
        var registeredEvents: [Any] = []

        func register(event: Any) {
            registeredEvents.append(event)
        }
    }

    // MARK: - Helpers

    private func makeAgreement(
        id: String,
        mandatory: Bool
    ) -> BehavioralBiometricAgreement {
        BehavioralBiometricAgreement(
            id: id,
            consentType: "test",
            textShort: "",
            textFull: "",
            isMandatory: mandatory
        )
    }

    // MARK: - Tests

    func test_onAppear_loadsAgreementsSuccessfully() async {
        let network = NetworkServiceMock()
        network.agreementsResult = .success([
            makeAgreement(id: "1", mandatory: true)
        ])

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State()
        ) {
            BehavioralBiometricAgreementsReducer(
                networkService: network,
                statusStorage: StatusStorageMock(),
                dashboardRefresher: DashboardRefresherMock(),
                behex: BehexMock()
            )
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(.onDidLoadAgreements) {
            $0.isLoading = false
            $0.agreements.count == 1
        }
    }

    func test_primaryButtonTap_withMissingMandatoryAgreements_setsUnselectedIds() async {
        let agreements = [
            makeAgreement(id: "A", mandatory: true),
            makeAgreement(id: "B", mandatory: false)
        ]

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State(
                agreements: agreements
            )
        ) {
            BehavioralBiometricAgreementsReducer(
                networkService: NetworkServiceMock(),
                statusStorage: StatusStorageMock(),
                dashboardRefresher: DashboardRefresherMock(),
                behex: BehexMock()
            )
        }

        await store.send(.onPrimaryButtonTap)

        await store.receive(.onValidationMandatoryAgreementsResult(["A"])) {
            $0.unselectedMandatoryAgreementsIds = ["A"]
        }
    }

    func test_primaryButtonTap_allMandatorySelected_opensMPinBottomSheet() async {
        let agreements = [
            makeAgreement(id: "A", mandatory: true)
        ]

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State(
                agreements: agreements,
                checkedAgreemntsIndexes: [0]
            )
        ) {
            BehavioralBiometricAgreementsReducer(
                networkService: NetworkServiceMock(),
                statusStorage: StatusStorageMock(),
                dashboardRefresher: DashboardRefresherMock(),
                behex: BehexMock()
            )
        }

        await store.send(.onPrimaryButtonTap)

        await store.receive(.onValidationMandatoryAgreementsResult([])) {
            $0.unselectedMandatoryAgreementsIds = []
            $0.destination = .mPinBottomSheet
        }
    }

    func test_onReceiveMPin_enablesBehavioralBiometricSuccessfully() async {
        let network = NetworkServiceMock()
        network.agreementsResult = .success([])

        let statusStorage = StatusStorageMock()
        let dashboard = DashboardRefresherMock()

        let agreement = makeAgreement(id: "A", mandatory: true)

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State(
                agreements: [agreement],
                checkedAgreemntsIndexes: [0]
            )
        ) {
            BehavioralBiometricAgreementsReducer(
                networkService: network,
                statusStorage: statusStorage,
                dashboardRefresher: dashboard,
                behex: BehexMock()
            )
        }

        await store.send(.onReceiveMPin(FakePin())) {
            $0.isLoading = true
        }

        await store.receive(.didEnableBehavioralBiometric) {
            $0.isLoading = false
            $0.destination = .enabledBehavioralBiometricSuccess
        }

        XCTAssertEqual(statusStorage.isEnabled, true)
        XCTAssertTrue(dashboard.didRefresh)
        XCTAssertTrue(network.changeStatusCalled)
    }

    func test_onError_setsDestinationError() async {
        let network = NetworkServiceMock()
        network.agreementsResult = .failure(BehavioralBiometricError.timeout)

        let store = TestStore(
            initialState: BehavioralBiometricAgreementsReducer.State()
        ) {
            BehavioralBiometricAgreementsReducer(
                networkService: network,
                statusStorage: StatusStorageMock(),
                dashboardRefresher: DashboardRefresherMock(),
                behex: BehexMock()
            )
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(.onError(.timeout)) {
            $0.isLoading = false
            $0.destination = .error(.timeout)
        }
    }
}
