import Assembly
import BehavioralBiometricLogger
import ComposableArchitecture
import Dependencies
import Foundation
@preconcurrency import IKOCommon
import SwinjectAutoregistration

enum BehavioralBiometricAgreementsErrorType: Error, Sendable, Equatable {
    case agreements
    case enableBehavioralBiometric
}

@Reducer
struct BehavioralBiometricAgreementsReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var isLoading: Bool = false
        var agreements: [BehavioralBiometricAgreement] = []
        var didUpdateAgreements: Bool = false
        @Presents var destination: Destination.State?
        var errorType: BehavioralBiometricAgreementsErrorType?
        var checkedAgreemntsIndexes: [Int] = []
        var unselectedMandatoryAgreementsIds: [String] = []
    }

    enum Action: Sendable {
        case onCheckAgreementsChanged([Int])
        case onPrimaryButtonTap
        case onValidationMandatoryAgreementsResult([String])
        case onMoreInformationTap
        case onResetNavigation
        case onError(BehavioralBiometricAgreementsErrorType)
        case onDidLoadAgreements([BehavioralBiometricAgreement])
        case onAppear
        case didEnableBehavioralBiometric
        case onReceiveMPin(IKOUIPin)
        case onAgreementsUpdated
        case onTryAgain
    }

    @Reducer(state: .equatable, .sendable, action: .sendable)
    public enum Destination {
        case enabledBehavioralBiometricSuccess
        case moreInfo
        case mPinBottomSheet
        case error
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
                return loadAgreements()
            case let .onDidLoadAgreements(agreements):
                state.agreements = agreements
                state.isLoading = false
                return .none
            case .onAgreementsUpdated:
                state.didUpdateAgreements = true
                return .none
            case let .onError(type):
                state.isLoading = false
                state.errorType = type
                state.destination = .error
                return .none
            case let .onCheckAgreementsChanged(checkedAgreemntsIndexes):
                state.checkedAgreemntsIndexes = checkedAgreemntsIndexes
                return .none
            case let .onValidationMandatoryAgreementsResult(unselectedMandatoryAgreementsIds):
                if unselectedMandatoryAgreementsIds.isEmpty {
                    state.unselectedMandatoryAgreementsIds = []
                    state.destination = .mPinBottomSheet
                } else {
                    state.unselectedMandatoryAgreementsIds = unselectedMandatoryAgreementsIds
                }
                return .none
            case .onPrimaryButtonTap:
                return validateMandatoryAgreementsSelection(agreements: state.agreements, checkedAgreementIndexes: state.checkedAgreemntsIndexes)
            case let .onReceiveMPin(mPin):
                state.isLoading = true
                let agreements = state.checkedAgreemntsIndexes.map { state.agreements[$0]
                }
                return enableBehavioralBiometric(mPin: mPin, agreements: agreements)
            case .didEnableBehavioralBiometric:
                state.isLoading = false
                state.destination = .enabledBehavioralBiometricSuccess
                return .none
            case .onMoreInformationTap:
                state.destination = .moreInfo
                return .none
            case .onResetNavigation:
                state.destination = nil
                return .none
            case .onTryAgain:
                switch state.errorType {
                case .agreements:
                    state.isLoading = true
                    return loadAgreements()
                case .enableBehavioralBiometric:
                    state.destination = .mPinBottomSheet
                    return .none
                case .none:
                    return .none
                }
            }
        }
    }

    private func validateMandatoryAgreementsSelection(agreements: [BehavioralBiometricAgreement], checkedAgreementIndexes: [Int]) -> Effect<Action> {
        .run { send in
            var unselectedMandatoryAgreements: [String] = []
            agreements.enumerated().forEach { index, item in
                if item.isMandatory, !checkedAgreementIndexes.contains(where: { $0 == index }) {
                    unselectedMandatoryAgreements.append(item.id)
                }
            }
            await send(.onValidationMandatoryAgreementsResult(unselectedMandatoryAgreements))
        }
    }

    private func loadAgreements() -> Effect<Action> {
        .run { send in
            do {
                let agreements = try await networkService.getBehavioralBiometricAgreements()
                await send(.onDidLoadAgreements(agreements))
            } catch {
                await send(.onError(.agreements))
            }
        }
    }

    private func enableBehavioralBiometric(mPin: IKOUIPin, agreements: [BehavioralBiometricAgreement]) -> Effect<Action> {
        .run { send in
            do {
                try await networkService.changeBehavioralBiometricStatus(
                    isEnabled: true,
                    mPin: mPin,
                    agreements: agreements)
                statusStorage.changeBehavioralBiometricStatus(isEnabled: true)
                await send(.didEnableBehavioralBiometric)
            } catch {
                await send(.onError(.enableBehavioralBiometric))
            }
        }
    }
}
