@testable import BehavioralBiometric
import Behex
import ComposableArchitecture
import XCTest

@MainActor
final class BehavioralBiometricStatusReducerTests: XCTestCase {
    func test_onAppear_loadsStatusSuccessfully() async {
        let state = BehavioralBiometricState(
            enabled: true,
            agreementsDate: "14.04.2015",
            agreements: []
        )
        let network = BehavioralBiometricNetworkServiceProviderMock()
        network.getBehavioralBiometricStateResult = .success(state)

        let store = makeStore(network: network)

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.onDidLoadStatus, state) {
            $0.status = state
            $0.isBehavioralBiometricEnabled = true
            $0.isLoading = false
        }
    }

    func test_onPrimaryButtonTap_whenEnabled_opensDisableFlow_andLogsEvent() async {
        let store = makeStore(
            state: .init(isBehavioralBiometricEnabled: true),
        )

        await store.send(.onPrimaryButtonTap) {
            $0.destination = .disableBehavioralBiometric
        }
    }

    func test_onPrimaryButtonTap_whenDisabled_opensEnableFlow_andLogsEvent() async {
        let store = makeStore(
            state: .init(isBehavioralBiometricEnabled: false),
        )

        await store.send(.onPrimaryButtonTap) {
            $0.destination = .enableBehavioralBiometric
        }
    }

    func test_onDisableBehavioralBiometric_opensMPinBottomSheet() async {
        let store = makeStore()

        await store.send(.onDisableBehavioralBiometric) {
            $0.destination = .mPinBottomSheet
        }
    }

    func test_onReceiveMPin_successfullyDisablesBiometric() async {
        let state = BehavioralBiometricState(
            enabled: false,
            agreementsDate: "14.04.2015",
            agreements: []
        )
        let network = BehavioralBiometricNetworkServiceProviderMock()
        network.changeBehavioralBiometricStatusResult = .success(())
        network.getBehavioralBiometricStateResult = .success(state)

        let store = makeStore(network: network)

        await store.send(.onReceiveMPin(IKOUIPinMock())) {
            $0.isLoading = true
        }

        await store.receive(\.onSuccessfullDisableBehavioralBiometric) {
            $0.destination = .successfullDisableBehavioralBiometric
        }

        await store.receive(\.onDidLoadStatus, state) {
            $0.status = state
            $0.isBehavioralBiometricEnabled = false
            $0.isLoading = false
        }
    }

    func test_onError_setsErrorDestination() async {
        let network = BehavioralBiometricNetworkServiceProviderMock()
        let error = BehavioralBiometricError.unknown
        network.getBehavioralBiometricStateResult = .failure(error)

        let store = makeStore(network: network)

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.onError, error) {
            $0.destination = .error(error)
        }
    }

    func test_onResetDestination_clearsDestination() async {
        let network = BehavioralBiometricNetworkServiceProviderMock()
        let store = makeStore(
            state: .init(destination: .explanation),
            network: network
        )

        await store.send(.onResetDestination) {
            $0.destination = nil
        }
    }

    // MARK: - Helpers

    private func makeStore(
        state: BehavioralBiometricStatusReducer.State = .init(),
        network: BehavioralBiometricNetworkServiceProviderMock = .init(),
        storage: BehavioralBiometricStatusStoreMock = .init()
    ) -> TestStore<
        BehavioralBiometricStatusReducer.State,
        BehavioralBiometricStatusReducer.Action
    > {
        TestStore(initialState: state) {
            BehavioralBiometricStatusReducer(
                networkService: network,
                statusStorage: storage,
                behex: BehavioralBiometricBehexMock()
            )
        }
    }
}
