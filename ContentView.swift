import ComposableArchitecture
import UIKit
import CoreTelephony
import Foundation

@Reducer
struct ESimActivationReducer {
    @ObservableState
    struct State: Sendable {
        var destination: Destination?
        let data: ESimActivationData
        var isLoading = true
        var isSystemConfiguratorAvailable = false
        var currentNumberOfInstalledSims: Int = 0
    }

    @CasePathable
    enum Action: Sendable {
        case onAppear
        case onNumberSimInstalled(Int)
        case onActivationSuccess
        case onManualESimAdd
        case onOpenSystemConfigurator
        case onESimNotSupported
        case onCopyTap(String)
        case onDeviceSettingTap
        case onAppDidBecomeActive
    }

    @CasePathable
    enum Destination: Sendable {
        case esimNotSupported
        case activationSuccess
        case eSimPhoneSettings
        case activation(String)
    }

    let eSimManager: ESimProvisioningManaging

    init(eSimManager: ESimProvisioningManaging) {
        self.eSimManager = eSimManager
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return updateNumberOfInstalledSims()

            case let .onNumberSimInstalled(simsCount):
                state.currentNumberOfInstalledSims = simsCount
                return checkESimAvailability(configuratorLink: state.data.iosActivationUrl)

            case .onESimNotSupported:
                state.destination = .esimNotSupported
                return .none

            case .onActivationSuccess:
                state.destination = .activationSuccess
                return .none

            case .onManualESimAdd:
                state.isLoading = false
                return .none

            case .onOpenSystemConfigurator:
                state.isSystemConfiguratorAvailable = true
                state.isLoading = false
                state.destination = .activation(state.data.iosActivationUrl)
                return .none

            case let .onCopyTap(text):
                UIPasteboard.general.string = text
                return .none

            case .onDeviceSettingTap:
                if state.isSystemConfiguratorAvailable {
                    state.destination = .activation(state.data.iosActivationUrl)
                } else {
                    state.destination = .eSimPhoneSettings
                }
                return .none

            case .onAppDidBecomeActive:
                if state.currentNumberOfInstalledSims < eSimManager.numberOfAvailableSims() {
                    state.destination = .activationSuccess
                }
                return .none
            }
        }
    }

    func checkESimAvailability(configuratorLink: String) -> Effect<Action> {
        .run { send in
            if await eSimManager.isESimSupportedByDevice() {
                if await eSimManager.isSystemESimConfiguratorAvailable(configuratorLink: configuratorLink) {
                    await send(.onOpenSystemConfigurator)
                } else {
                    await send(.onManualESimAdd)
                }
            } else {
                await send(.onESimNotSupported)
            }
        }
    }

    func updateNumberOfInstalledSims() -> Effect<Action> {
        .run { send in
            let simsCount = eSimManager.numberOfAvailableSims()
            await send(.onNumberSimInstalled(simsCount))
        }
    }
}



import CoreTelephony
import UIKit

protocol ESimProvisioningManaging: Sendable {
    @MainActor func isESimSupportedByDevice() -> Bool
    @MainActor func isSystemESimConfiguratorAvailable(configuratorLink: String) -> Bool
    func numberOfAvailableSims() -> Int
}

final class ESimProvisioningManager: ESimProvisioningManaging {
    func numberOfAvailableSims() -> Int {
        let info = CTTelephonyNetworkInfo()
        let numberOfProviders = info.serviceCurrentRadioAccessTechnology?.keys.count ?? 0
        return numberOfProviders
    }
    
    @MainActor func isSystemESimConfiguratorAvailable(configuratorLink: String) -> Bool {
        guard let url = URL(string: configuratorLink) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    @MainActor func isESimSupportedByDevice() -> Bool {
        isESimOnlyDevice() || isDualSimDevice() || containsMobileDataSettings()
    }

    @MainActor private func containsMobileDataSettings() -> Bool {
        if let url = URL(string: "App-Prefs:root=MOBILE_DATA_SETTINGS_ID") {
            return UIApplication.shared.canOpenURL(url)
        } else {
            return false
        }
    }

    private func isESimOnlyDevice() -> Bool {
        let services = CTTelephonyNetworkInfo().dataServiceIdentifier

        if services == nil || services?.isEmpty == true {
            return true
        } else {
            return false
        }
    }

    private func isDualSimDevice() -> Bool {
        if let radioAccesses = CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology {
            return radioAccesses.count > 1
        } else {
            return false
        }
    }
}



struct ESimActivationData: Equatable, Sendable {
    let lpa: String
    let smdpAddress: String
    let activationCode: String
    let iosActivationUrl: String
    let confirmationCode: String
    let carrierName: String
    let planLabel: String
    let cardNumber: String
}
