import ComposableArchitecture
import Testing
@testable import ESim

@MainActor
@Suite("ESimActivationReducer")
struct ESimActivationReducerTests {

    // MARK: - onAppear

    @Suite("onAppear")
    struct OnAppear {

        @Test("System configurator available → opens activation")
        func systemConfiguratorAvailable() async {
            let env = TestEnvironment(
                isESimSupported: true,
                isConfiguratorAvailable: true
            )

            let store = env.makeStore()

            await store.send(.onAppear)

            await store.receive(\.eSimAvailabilityChecked, .systemConfigurator) {
                $0.isSystemConfiguratorAvailable = true
                $0.isLoading = false
                $0.destination = .activation(env.activationURL)
            }

            #expect(env.behex.events.contains(.ESim_InstallSplash_view_Show))
            #expect(env.behex.events.contains(.ESim_InstallDetails_view_Show))
        }

        @Test("eSIM supported but no configurator → manual flow")
        func manualFlow() async {
            let env = TestEnvironment(
                isESimSupported: true,
                isConfiguratorAvailable: false
            )

            let store = env.makeStore()

            await store.send(.onAppear)

            await store.receive(\.eSimAvailabilityChecked, .manual) {
                $0.isSystemConfiguratorAvailable = false
                $0.isLoading = false
                $0.destination = nil
            }

            #expect(env.behex.events.contains(.ESim_InstallDetails_view_Show))
        }

        @Test("eSIM not supported → not supported screen")
        func eSimNotSupported() async {
            let env = TestEnvironment(isESimSupported: false)

            let store = env.makeStore()

            await store.send(.onAppear)

            await store.receive(\.eSimAvailabilityChecked, .notSupported) {
                $0.destination = .esimNotSupported
            }

            #expect(env.behex.events.contains(.ESim_InstallError_UnsupportedDevice_view_Show))
        }
    }

    // MARK: - onDeviceSettingTap

    @Suite("onDeviceSettingTap")
    struct OnDeviceSettingTap {

        @Test("With system configurator → activation")
        func withConfigurator() async {
            let env = TestEnvironment()
            var state = TestEnvironment.initialState
            state.isSystemConfiguratorAvailable = true

            let store = env.makeStore(initialState: state)

            await store.send(.onDeviceSettingTap) {
                $0.destination = .activation(env.activationURL)
            }

            #expect(env.behex.events.contains(.ESim_InstallDetails_btn_PhoneSettings))
        }

        @Test("Without system configurator → phone settings")
        func withoutConfigurator() async {
            let env = TestEnvironment()
            var state = TestEnvironment.initialState
            state.isSystemConfiguratorAvailable = false

            let store = env.makeStore(initialState: state)

            await store.send(.onDeviceSettingTap) {
                $0.destination = .phoneSettings
            }

            #expect(env.behex.events.contains(.ESim_InstallDetails_btn_PhoneSettings))
        }
    }

    // MARK: - Copy actions

    @Suite("Copy actions")
    struct CopyActions {

        @Test("Activation code copy shows toast")
        func activationCodeCopy() async {
            let env = TestEnvironment()
            let store = env.makeStore()

            await store.send(.onActivationCodeCopyTap)

            #expect(env.toast.didShowToast)
            #expect(env.behex.events.contains(.ESim_InstallDetails_ActivationCode_btn_Copy))
        }

        @Test("SMDP address copy shows toast")
        func smdpCopy() async {
            let env = TestEnvironment()
            let store = env.makeStore()

            await store.send(.onSMDPCopyTap)

            #expect(env.toast.didShowToast)
            #expect(env.behex.events.contains(.ESim_InstallDetails_AddressSMDP_btn_Copy))
        }
    }
}




@MainActor
private struct TestEnvironment {

    static let activationURL = "https://test.esim.com/activate"

    static let initialState = ESimActivationReducer.State(
        data: .mock,
        isLoading: true,
        isSystemConfiguratorAvailable: false
    )

    let manager: ESimProvisioningManagerMock
    let behex: ESimBehexMock
    let toast: ESimToastManagerMock

    init(
        isESimSupported: Bool = true,
        isConfiguratorAvailable: Bool = false
    ) {
        let manager = ESimProvisioningManagerMock()
        manager.mockIsESimSupported = isESimSupported
        manager.mockIsConfiguratorAvailable = isConfiguratorAvailable

        self.manager = manager
        self.behex = ESimBehexMock()
        self.toast = ESimToastManagerMock()
    }

    func makeStore(
        initialState: ESimActivationReducer.State = Self.initialState
    ) -> TestStore<ESimActivationReducer.State, ESimActivationReducer.Action> {
        TestStore(
            initialState: initialState,
            reducer: {
                ESimActivationReducer(
                    eSimManager: manager,
                    toastManager: toast,
                    behex: behex
                )
            }
        )
    }
}
