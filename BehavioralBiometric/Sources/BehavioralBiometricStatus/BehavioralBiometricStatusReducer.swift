import Assembly
import BehavioralBiometricLogger
import ComposableArchitecture
import Foundation
@preconcurrency import IKOCommon
import SwinjectAutoregistration

enum BehavioralBiometricStatusErrorType: Error, Sendable, Equatable {
    case disableBehavioralBiometric
    case loadStatus
}

@Reducer
struct BehavioralBiometricStatusReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var isLoading: Bool = false
        var status: BehavioralBiometricState?
        var isBehavioralBiometricEnabled: Bool = false
        var errorType: BehavioralBiometricStatusErrorType? = nil
        @Presents var destination: Destination.State?
    }

    @Reducer(state: .equatable, .sendable, action: .sendable)
    public enum Destination {
        case disableBehavioralBiometric
        case enableBehavioralBiometric
        case mPinBottomSheet
        case error
        case explanation
        case successfullDisableBehavioralBiometric
    }

    @CasePathable
    enum Action: Sendable {
        case onAppear
        case onDidLoadStatus(BehavioralBiometricState)
        case onMoreInfoLinkTap
        case onPrimaryButtonTap
        case destination(PresentationAction<Destination.Action>)
        case onReceiveMPin(IKOUIPin)
        case onDisableBehavioralBiometric
        case onSuccessfullDisableBehavioralBiometric
        case onError(BehavioralBiometricStatusErrorType)
        case onTryAgain
        case onResetDestination
    }

    private let networkService: BehavioralBiometricNetworkServiceProviding
    private let statusStorage: BehavioralBiometricStatusStoring

    init(
        networkService: BehavioralBiometricNetworkServiceProviding = IKOAssembler.resolver~>,
        statusStorage: BehavioralBiometricStatusStoring = IKOAssembler.resolver~>
    ) {
        self.networkService = networkService
        self.statusStorage = statusStorage
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return loadStatus()
            case let .onDidLoadStatus(status):
                state.status = status
                state.isBehavioralBiometricEnabled = status.enabled
                state.isLoading = false
                return .none
            case .onMoreInfoLinkTap:
                state.destination = .explanation
                return .none
            case .onPrimaryButtonTap:
                if state.isBehavioralBiometricEnabled {
                    state.destination = .disableBehavioralBiometric
                } else {
                    state.destination = .enableBehavioralBiometric
                }
                return .none
            case let .onReceiveMPin(mPin):
                state.isLoading = true
                return disableBehavioralBiometric(mPin: mPin)
            case .onDisableBehavioralBiometric:
                state.destination = .mPinBottomSheet
                return .none
            case .onSuccessfullDisableBehavioralBiometric:
                state.destination = .successfullDisableBehavioralBiometric
                return loadStatus()
            case let .onError(errorType):
                state.errorType = errorType
                state.destination = .error
                return .none
            case .onTryAgain:
                switch state.errorType {
                case .disableBehavioralBiometric:
                    state.destination = .mPinBottomSheet
                    return .none
                case .loadStatus:
                    return loadStatus()
                case .none:
                    return .none
                }
            case .onResetDestination:
                state.destination = nil
                return .none
            case .destination:
                return .none
            }
        }
    }

    private func loadStatus() -> Effect<Action> {
        .run { send in
            do {
                let status = try await networkService.getBehavioralBiometricState()
                await send(.onDidLoadStatus(status))
            } catch {
                await send(.onError(.loadStatus))
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
            } catch {
                await send(.onError(.disableBehavioralBiometric))
            }
        }
    }
}
