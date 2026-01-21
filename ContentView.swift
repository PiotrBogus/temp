import BehavioralBiometricLogger
@preconcurrency import Behex
import ComposableArchitecture
import Foundation
@preconcurrency import IKOCommon
@preconcurrency import UIComponents

@Reducer
struct BehavioralBiometricStatusReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var isLoading = false
        var status: BehavioralBiometricState?
        var isBehavioralBiometricEnabled = false
        var destination: Destination?
    }

    @CasePathable
    public enum Destination: Sendable, Equatable {
        case disableBehavioralBiometric
        case enableBehavioralBiometric
        case mPinBottomSheet
        case error(BehavioralBiometricError)
        case explanation
        case successfullDisableBehavioralBiometric
    }

    @CasePathable
    enum Action: Sendable {
        case onAppear
        case onDidLoadStatus(BehavioralBiometricState)
        case onMoreInfoLinkTap
        case onPrimaryButtonTap
        case onReceiveMPin(IKOUIPin)
        case onDisableBehavioralBiometric
        case onSuccessfullDisableBehavioralBiometric
        case onError(BehavioralBiometricError)
        case onTryAgain
        case onResetDestination
    }

    private let networkService: BehavioralBiometricNetworkServiceProviding
    private let statusStorage: BehavioralBiometricStatusStoring
    private let behex: Behex

    init(
        networkService: BehavioralBiometricNetworkServiceProviding,
        statusStorage: BehavioralBiometricStatusStoring,
        behex: Behex
    ) {
        self.networkService = networkService
        self.statusStorage = statusStorage
        self.behex = behex
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return loadStatus()

            case .onDidLoadStatus(let status):
                state.status = status
                state.isBehavioralBiometricEnabled = status.enabled
                state.isLoading = false
                return .none

            case .onMoreInfoLinkTap:
                state.destination = .explanation
                return .none

            case .onPrimaryButtonTap:
                if state.isBehavioralBiometricEnabled {
                    behex.register(event: .BehavioralBiometric_TurnOffBehavioralBiometricBottomSheet_view_Show)
                    state.destination = .disableBehavioralBiometric
                } else {
                    behex.register(event: .BehavioralBiometric_AgreementsScreen_btn_TurnOn)
                    state.destination = .enableBehavioralBiometric
                }
                return .none

            case .onReceiveMPin(let mPin):
                state.isLoading = true
                return disableBehavioralBiometric(mPin: mPin)

            case .onDisableBehavioralBiometric:
                state.destination = .mPinBottomSheet
                return .none

            case .onSuccessfullDisableBehavioralBiometric:
                state.destination = .successfullDisableBehavioralBiometric
                return loadStatus()

            case .onError(let error):
                state.destination = .error(error)
                return .none

            case .onTryAgain:
                if state.status == nil {
                    return loadStatus()
                } else {
                    state.destination = .mPinBottomSheet
                    return .none
                }

            case .onResetDestination:
                state.destination = nil
                return .none
            }
        }
    }

    private func loadStatus() -> Effect<Action> {
        .run { send in
            do {
                let status = try await networkService.getBehavioralBiometricState()
                await send(.onDidLoadStatus(status))
            } catch let error as BehavioralBiometricError {
                await send(.onError(error))
            }
        }
    }

    private func disableBehavioralBiometric(mPin: IKOUIPin) -> Effect<Action> {
        .run { send in
            do {
                try await networkService.changeBehavioralBiometricStatus(
                    isEnabled: false,
                    mPin: mPin,
                    agreements: nil
                )
                await send(.onSuccessfullDisableBehavioralBiometric)
            } catch let error as BehavioralBiometricError {
                await send(.onError(error))
            }
        }
    }
}
