import XCTest
import ComposableArchitecture
@testable import YourModuleName

final class BehavioralBiometricStatusReducerTests: XCTestCase {

    // MARK: - Mocks

    private final class BehexMock: Behex {
        private(set) var events: [Any] = []

        func register(event: Any) {
            events.append(event)
        }
    }

    private final class NetworkServiceMock: BehavioralBiometricNetworkServiceProviding {
        var getStatusResult: Result<BehavioralBiometricState, BehavioralBiometricError>!
        var changeStatusResult: Result<Void, BehavioralBiometricError>!

        func getBehavioralBiometricState() async throws -> BehavioralBiometricState {
            try getStatusResult.get()
        }

        func changeBehavioralBiometricStatus(
            isEnabled: Bool,
            mPin: IKOUIPin,
            agreements: [BehavioralBiometricAgreement]?
        ) async throws {
            try changeStatusResult.get()
        }
    }

    private final class StatusStorageMock: BehavioralBiometricStatusStoring {
        private(set) var isEnabled: Bool?

        func changeBehavioralBiometricStatus(isEnabled: Bool) {
            self.isEnabled = isEnabled
        }
    }

    // MARK: - Helpers

    private func makeStore(
        state: BehavioralBiometricStatusReducer.State = .init(),
        network: NetworkServiceMock,
        storage: StatusStorageMock = .init(),
        behex: BehexMock = .init()
    ) -> TestStore<
        BehavioralBiometricStatusReducer.State,
        BehavioralBiometricStatusReducer.Action
    > {
        TestStore(initialState: state) {
            BehavioralBiometricStatusReducer(
                networkService: network,
                statusStorage: storage,
                behex: behex
            )
        }
    }

    // MARK: - Tests

    func test_onAppear_loadsStatusSuccessfully() async {
        let network = NetworkServiceMock()
        network.getStatusResult = .success(.init(enabled: true))

        let store = makeStore(network: network)

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(.onDidLoadStatus(.init(enabled: true))) {
            $0.status = .init(enabled: true)
            $0.isBehavioralBiometricEnabled = true
            $0.isLoading = false
        }
    }

    func test_onPrimaryButtonTap_whenEnabled_opensDisableFlow_andLogsEvent() async {
        let network = NetworkServiceMock()
        let behex = BehexMock()

        let store = makeStore(
            state: .init(isBehavioralBiometricEnabled: true),
            network: network,
            behex: behex
        )

        await store.send(.onPrimaryButtonTap) {
            $0.destination = .disableBehavioralBiometric
        }

        XCTAssertEqual(behex.events.count, 1)
    }

    func test_onPrimaryButtonTap_whenDisabled_opensEnableFlow_andLogsEvent() async {
        let network = NetworkServiceMock()
        let behex = BehexMock()

        let store = makeStore(
            state: .init(isBehavioralBiometricEnabled: false),
            network: network,
            behex: behex
        )

        await store.send(.onPrimaryButtonTap) {
            $0.destination = .enableBehavioralBiometric
        }

        XCTAssertEqual(behex.events.count, 1)
    }

    func test_onDisableBehavioralBiometric_opensMPinBottomSheet() async {
        let network = NetworkServiceMock()
        let store = makeStore(network: network)

        await store.send(.onDisableBehavioralBiometric) {
            $0.destination = .mPinBottomSheet
        }
    }

    func test_onReceiveMPin_successfullyDisablesBiometric() async {
        let network = NetworkServiceMock()
        network.changeStatusResult = .success(())
        network.getStatusResult = .success(.init(enabled: false))

        let store = makeStore(network: network)

        await store.send(.onReceiveMPin(.init("1234"))) {
            $0.isLoading = true
        }

        await store.receive(.onSuccessfullDisableBehavioralBiometric) {
            $0.destination = .successfullDisableBehavioralBiometric
        }

        await store.receive(.onDidLoadStatus(.init(enabled: false))) {
            $0.status = .init(enabled: false)
            $0.isBehavioralBiometricEnabled = false
            $0.isLoading = false
        }
    }

    func test_onError_setsErrorDestination() async {
        let network = NetworkServiceMock()
        let error = BehavioralBiometricError.unknown
        network.getStatusResult = .failure(error)

        let store = makeStore(network: network)

        await store.send(.onAppear)

        await store.receive(.onError(error)) {
            $0.destination = .error(error)
        }
    }

    func test_onResetDestination_clearsDestination() async {
        let network = NetworkServiceMock()
        let store = makeStore(
            state: .init(destination: .explanation),
            network: network
        )

        await store.send(.onResetDestination) {
            $0.destination = nil
        }
    }
}
