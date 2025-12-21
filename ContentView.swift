@preconcurrency import Behex
import ComposableArchitecture
import Foundation
import Labels
import UIKit

@Reducer
struct ESimActivationReducer: Sendable {
    @ObservableState
    struct State: Sendable, Equatable {
        var destination: Destination?
        let data: ESimActivationData
        var isLoading = true
        var isSystemConfiguratorAvailable = false
    }

    @CasePathable
    enum Action: Sendable {
        case onAppear
        case eSimAvailabilityChecked(ESimAvailability)
        case onActivationCodeCopyTap
        case onSMDPCopyTap
        case onDeviceSettingTap
    }

    @CasePathable
    enum ESimAvailability: Sendable, Equatable {
        case notSupported
        case systemConfigurator
        case manual
    }

    @CasePathable
    enum Destination: Sendable, Equatable {
        case esimNotSupported
        case phoneSettings
        case activation(String)
    }

    private let eSimManager: ESimProvisioningManaging
    private let behex: Behex
    private let toastManager: ESimToastManaging

    init(
        eSimManager: ESimProvisioningManaging,
        toastManager: ESimToastManaging,
        behex: Behex
    ) {
        self.eSimManager = eSimManager
        self.toastManager = toastManager
        self.behex = behex
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .eSimAvailabilityChecked(availability):
                handleESimAvailability(availability: availability, state: &state)
                return .none

            case .onAppear:
                behex.register(event: .ESim_InstallSplash_view_Show)
                return checkESimAvailability(configuratorLink: state.data.iosActivationUrl)

            case .onActivationCodeCopyTap:
                behex.register(event: .ESim_InstallDetails_ActivationCode_btn_Copy)
                UIPasteboard.general.string = state.data.activationCode
                toastManager.show(with: .labels.ESim_InstallDetails_lbl_ActivationCodeCopyMessage.localized)
                return .none

            case .onSMDPCopyTap:
                behex.register(event: .ESim_InstallDetails_AddressSMDP_btn_Copy)
                UIPasteboard.general.string = state.data.smdpAddress
                toastManager.show(with: .labels.ESim_InstallDetails_lbl_SMDPCodeCopyMessage.localized)
                return .none

            case .onDeviceSettingTap:
                behex.register(event: .ESim_InstallDetails_btn_PhoneSettings)
                if state.isSystemConfiguratorAvailable {
                    state.destination = .activation(state.data.iosActivationUrl)
                } else {
                    state.destination = .phoneSettings
                }
                return .none
            }
        }
    }

    private func checkESimAvailability(configuratorLink: String) -> Effect<Action> {
        .run { send in
            guard await eSimManager.isESimSupportedByDevice() else {
                return await send(.eSimAvailabilityChecked(.notSupported))
            }

            let canOpen = await eSimManager.isSystemESimConfiguratorAvailable(configuratorLink: configuratorLink)

            return await send(.eSimAvailabilityChecked(canOpen ? .systemConfigurator : .manual))
        }
    }

    private func handleESimAvailability(availability: ESimAvailability, state: inout State) {
        switch availability {
        case .notSupported:
            behex.register(event: .ESim_InstallError_UnsupportedDevice_view_Show)
            state.destination = .esimNotSupported

        case .manual:
            behex.register(event: .ESim_InstallDetails_view_Show)
            state.isSystemConfiguratorAvailable = false
            state.isLoading = false

        case .systemConfigurator:
            behex.register(event: .ESim_InstallDetails_view_Show)
            state.isSystemConfiguratorAvailable = true
            state.isLoading = false
            state.destination = .activation(state.data.iosActivationUrl)
        }
    }
}







import ComposableArchitecture
@testable import ESim
import XCTest

@MainActor
final class ESimActivationReducerTests: XCTestCase {
    // MARK: - onAppear Tests

    func testOnAppear_UpdatesNumberOfInstalledSims() async {
        let mockManager = ESimProvisioningManagerMock()
        let behexMock = ESimBehexMock()
        let toastmanager = ESimToastManagerMock()

        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(
                eSimManager: mockManager,
                toastManager: toastmanager,
                behex: behexMock
            )
            }
        )

        await store.send(.onAppear)
        await store.receive(\.onOpenSystemConfigurator) {
            $0.isSystemConfiguratorAvailable = true
            $0.isLoading = false
            $0.destination = .activation("https://test.esim.com/activate")
        }
    }

    // MARK: - onNumberSimInstalled Tests

    func testOnNumberSimInstalled_WithSystemConfigurator_OpensSystemConfigurator() async {
        let mockManager = ESimProvisioningManagerMock()
        mockManager.mockIsESimSupported = true
        mockManager.mockIsConfiguratorAvailable = true
        let behexMock = ESimBehexMock()
        let toastmanager = ESimToastManagerMock()

        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(
                eSimManager: mockManager,
                toastManager: toastmanager,
                behex: behexMock
            )
            }
        )

        await store.send(.onAppear)
        await store.receive(\.onOpenSystemConfigurator) {
            $0.isSystemConfiguratorAvailable = true
            $0.isLoading = false
            $0.destination = .activation("https://test.esim.com/activate")
        }
    }

    func testOnNumberSimInstalled_WithoutSystemConfigurator_TriggersManualAdd() async {
        let mockManager = ESimProvisioningManagerMock()
        mockManager.mockIsESimSupported = true
        mockManager.mockIsConfiguratorAvailable = false
        let behexMock = ESimBehexMock()
        let toastmanager = ESimToastManagerMock()

        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(
                eSimManager: mockManager,
                toastManager: toastmanager,
                behex: behexMock
            )
            }
        )

        await store.send(.onAppear)
        await store.receive(\.onManualESimAdd) {
            $0.isLoading = false
        }
    }

    func testOnNumberSimInstalled_ESimNotSupported_ShowsNotSupportedDestination() async {
        let mockManager = ESimProvisioningManagerMock()
        mockManager.mockIsESimSupported = false
        let behexMock = ESimBehexMock()
        let toastmanager = ESimToastManagerMock()

        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(
                eSimManager: mockManager,
                toastManager: toastmanager,
                behex: behexMock
            )
            }
        )

        await store.send(.onAppear)
        await store.receive(\.onESimNotSupported) {
            $0.destination = .esimNotSupported
        }
    }

    // MARK: - onESimNotSupported Tests

    func testOnESimNotSupported_SetsDestination() async {
        let mockManager = ESimProvisioningManagerMock()
        let behexMock = ESimBehexMock()
        let toastmanager = ESimToastManagerMock()

        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(
                eSimManager: mockManager,
                toastManager: toastmanager,
                behex: behexMock
            )
            }
        )

        await store.send(.onESimNotSupported) {
            $0.destination = .esimNotSupported
        }
    }

    // MARK: - onManualESimAdd Tests

    func testOnManualESimAdd_StopsLoading() async {
        let mockManager = ESimProvisioningManagerMock()
        let behexMock = ESimBehexMock()
        let toastmanager = ESimToastManagerMock()

        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(
                eSimManager: mockManager,
                toastManager: toastmanager,
                behex: behexMock
            )
            }
        )

        await store.send(.onManualESimAdd) {
            $0.isLoading = false
            $0.isSystemConfiguratorAvailable = false
        }
    }

    // MARK: - onOpenSystemConfigurator Tests

    func testOnOpenSystemConfigurator_UpdatesStateAndDestination() async {
        let mockManager = ESimProvisioningManagerMock()
        let behexMock = ESimBehexMock()
        let toastmanager = ESimToastManagerMock()

        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(
                eSimManager: mockManager,
                toastManager: toastmanager,
                behex: behexMock
            )
            }
        )

        await store.send(.onOpenSystemConfigurator) {
            $0.isSystemConfiguratorAvailable = true
            $0.isLoading = false
            $0.destination = .activation("https://test.esim.com/activate")
        }
    }

    // MARK: - onDeviceSettingTap Tests

    func testOnDeviceSettingTap_WithSystemConfigurator_OpensActivation() async {
        let mockManager = ESimProvisioningManagerMock()
        let behexMock = ESimBehexMock()
        let toastmanager = ESimToastManagerMock()

        var state = makeTestState()
        state.isSystemConfiguratorAvailable = true

        let store = TestStore(
            initialState: state,
            reducer: { ESimActivationReducer(
                eSimManager: mockManager,
                toastManager: toastmanager,
                behex: behexMock
            )
            }
        )

        await store.send(.onDeviceSettingTap) {
            $0.destination = .activation("https://test.esim.com/activate")
        }
    }

    func testOnDeviceSettingTap_WithoutSystemConfigurator_OpensPhoneSettings() async {
        let mockManager = ESimProvisioningManagerMock()
        let behexMock = ESimBehexMock()
        let toastmanager = ESimToastManagerMock()

        var state = makeTestState()
        state.isSystemConfiguratorAvailable = false

        let store = TestStore(
            initialState: state,
            reducer: { ESimActivationReducer(
                eSimManager: mockManager,
                toastManager: toastmanager,
                behex: behexMock
            )
            }
        )

        await store.send(.onDeviceSettingTap) {
            $0.destination = .phoneSettings
        }
    }

    // MARK: - Test Data

    private func makeTestState() -> ESimActivationReducer.State {
        ESimActivationReducer.State(
            data: .mock,
            isLoading: true,
            isSystemConfiguratorAvailable: false
        )
    }
}
