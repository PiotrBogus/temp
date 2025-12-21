import ComposableArchitecture
@testable import ESim
import XCTest

@MainActor
final class ESimActivationReducerTests: XCTestCase {

    // MARK: - onAppear

    func testOnAppear_SystemConfiguratorAvailable() async {
        let mockManager = ESimProvisioningManagerMock()
        mockManager.mockIsESimSupported = true
        mockManager.mockIsConfiguratorAvailable = true

        let store = TestStore(
            initialState: makeTestState(),
            reducer: {
                ESimActivationReducer(
                    eSimManager: mockManager,
                    toastManager: ESimToastManagerMock(),
                    behex: ESimBehexMock()
                )
            }
        )

        await store.send(.onAppear)

        await store.receive(.eSimAvailabilityChecked(.systemConfigurator)) {
            $0.isSystemConfiguratorAvailable = true
            $0.isLoading = false
            $0.destination = .activation("https://test.esim.com/activate")
        }
    }

    func testOnAppear_ManualESimFlow() async {
        let mockManager = ESimProvisioningManagerMock()
        mockManager.mockIsESimSupported = true
        mockManager.mockIsConfiguratorAvailable = false

        let store = TestStore(
            initialState: makeTestState(),
            reducer: {
                ESimActivationReducer(
                    eSimManager: mockManager,
                    toastManager: ESimToastManagerMock(),
                    behex: ESimBehexMock()
                )
            }
        )

        await store.send(.onAppear)

        await store.receive(.eSimAvailabilityChecked(.manual)) {
            $0.isSystemConfiguratorAvailable = false
            $0.isLoading = false
            $0.destination = nil
        }
    }

    func testOnAppear_ESimNotSupported() async {
        let mockManager = ESimProvisioningManagerMock()
        mockManager.mockIsESimSupported = false

        let store = TestStore(
            initialState: makeTestState(),
            reducer: {
                ESimActivationReducer(
                    eSimManager: mockManager,
                    toastManager: ESimToastManagerMock(),
                    behex: ESimBehexMock()
                )
            }
        )

        await store.send(.onAppear)

        await store.receive(.eSimAvailabilityChecked(.notSupported)) {
            $0.destination = .esimNotSupported
        }
    }

    // MARK: - onDeviceSettingTap

    func testOnDeviceSettingTap_WithSystemConfigurator() async {
        var state = makeTestState()
        state.isSystemConfiguratorAvailable = true

        let store = TestStore(
            initialState: state,
            reducer: {
                ESimActivationReducer(
                    eSimManager: ESimProvisioningManagerMock(),
                    toastManager: ESimToastManagerMock(),
                    behex: ESimBehexMock()
                )
            }
        )

        await store.send(.onDeviceSettingTap) {
            $0.destination = .activation("https://test.esim.com/activate")
        }
    }

    func testOnDeviceSettingTap_WithoutSystemConfigurator() async {
        var state = makeTestState()
        state.isSystemConfiguratorAvailable = false

        let store = TestStore(
            initialState: state,
            reducer: {
                ESimActivationReducer(
                    eSimManager: ESimProvisioningManagerMock(),
                    toastManager: ESimToastManagerMock(),
                    behex: ESimBehexMock()
                )
            }
        )

        await store.send(.onDeviceSettingTap) {
            $0.destination = .phoneSettings
        }
    }

    // MARK: - Copy actions

    func testOnActivationCodeCopyTap() async {
        let store = TestStore(
            initialState: makeTestState(),
            reducer: {
                ESimActivationReducer(
                    eSimManager: ESimProvisioningManagerMock(),
                    toastManager: ESimToastManagerMock(),
                    behex: ESimBehexMock()
                )
            }
        )

        await store.send(.onActivationCodeCopyTap)
    }

    func testOnSMDPCopyTap() async {
        let store = TestStore(
            initialState: makeTestState(),
            reducer: {
                ESimActivationReducer(
                    eSimManager: ESimProvisioningManagerMock(),
                    toastManager: ESimToastManagerMock(),
                    behex: ESimBehexMock()
                )
            }
        )

        await store.send(.onSMDPCopyTap)
    }

    // MARK: - Helpers

    private func makeTestState() -> ESimActivationReducer.State {
        ESimActivationReducer.State(
            data: .mock,
            isLoading: true,
            isSystemConfiguratorAvailable: false
        )
    }
}
