import Assembly
import BehavioralBiometricLogger
@preconcurrency import Behex
import ComposableArchitecture
import Dependencies
import Foundation
@preconcurrency import IKOCommon
import SwinjectAutoregistration
@preconcurrency import UIComponents

@Reducer
struct BehavioralBiometricAgreementsReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var isLoading = false
        var agreements: [BehavioralBiometricAgreement] = []
        var didUpdateAgreements = false
        var destination: Destination?
        var checkedAgreemntsIndexes: [Int] = []
        var unselectedMandatoryAgreementsIds: [String] = []
    }

    @CasePathable
    enum Action: Sendable {
        case onCheckAgreementsChanged([Int])
        case onPrimaryButtonTap
        case onValidationMandatoryAgreementsResult([String])
        case onMoreInformationTap
        case onError(BehavioralBiometricError)
        case onDidLoadAgreements([BehavioralBiometricAgreement])
        case onAppear
        case didEnableBehavioralBiometric
        case onReceiveMPin(IKOUIPin)
        case onAgreementsUpdated
        case onTryAgain
    }

    @CasePathable
    public enum Destination: Sendable, Equatable {
        case enabledBehavioralBiometricSuccess
        case moreInfo
        case mPinBottomSheet
        case error(BehavioralBiometricError)
    }

    private let networkService: BehavioralBiometricNetworkServiceProviding
    private let statusStorage: BehavioralBiometricStatusStoring
    private let dashboardRefresher: BehavioralBiometricDashboardRefreshing
    private let behex: Behex

    init(
        networkService: BehavioralBiometricNetworkServiceProviding = IKOAssembler.resolver~>,
        statusStorage: BehavioralBiometricStatusStoring = IKOAssembler.resolver~>,
        dashboardRefresher: BehavioralBiometricDashboardRefreshing = IKOAssembler.resolver~>,
        behex: Behex
    ) {
        self.networkService = networkService
        self.statusStorage = statusStorage
        self.dashboardRefresher = dashboardRefresher
        self.behex = behex
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                behex.register(event: .BehavioralBiometric_AgreementsScreen_view_Show)
                state.isLoading = true
                return loadAgreements()

            case .onDidLoadAgreements(let agreements):
                state.agreements = agreements
                state.isLoading = false
                return .none

            case .onAgreementsUpdated:
                state.didUpdateAgreements = true
                return .none

            case .onError(let error):
                state.isLoading = false
                state.destination = .error(error)
                return .none

            case .onCheckAgreementsChanged(let checkedAgreemntsIndexes):
                state.checkedAgreemntsIndexes = checkedAgreemntsIndexes
                return .none

            case .onValidationMandatoryAgreementsResult(let unselectedMandatoryAgreementsIds):
                if unselectedMandatoryAgreementsIds.isEmpty {
                    state.unselectedMandatoryAgreementsIds = []
                    behex.register(event: .BehavioralBiometric_TurnOnBehavioralBiometricPin_view_Show)
                    state.destination = .mPinBottomSheet
                } else {
                    state.unselectedMandatoryAgreementsIds = unselectedMandatoryAgreementsIds
                }
                return .none

            case .onPrimaryButtonTap:
                behex.register(event: .BehavioralBiometric_AgreementsScreen_btn_TurnOn)
                return validateMandatoryAgreementsSelection(agreements: state.agreements, checkedAgreementIndexes: state.checkedAgreemntsIndexes)

            case .onReceiveMPin(let mPin):
                state.isLoading = true
                let agreements = state.checkedAgreemntsIndexes.map { state.agreements[$0]
                }
                return enableBehavioralBiometric(mPin: mPin, agreements: agreements)

            case .didEnableBehavioralBiometric:
                state.isLoading = false
                state.destination = .enabledBehavioralBiometricSuccess
                dashboardRefresher.refresh()
                return .none

            case .onMoreInformationTap:
                state.destination = .moreInfo
                return .none

            case .onTryAgain:
                if state.agreements.isEmpty {
                    state.isLoading = true
                    return loadAgreements()
                } else {
                    state.destination = .mPinBottomSheet
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
            } catch let error as BehavioralBiometricError {
                await send(.onError(error))
            }
        }
    }

    private func enableBehavioralBiometric(mPin: IKOUIPin, agreements: [BehavioralBiometricAgreement]) -> Effect<Action> {
        .run { send in
            do {
                try await networkService.changeBehavioralBiometricStatus(
                    isEnabled: true,
                    mPin: mPin,
                    agreements: agreements
                )
                statusStorage.changeBehavioralBiometricStatus(isEnabled: true)
                await send(.didEnableBehavioralBiometric)
            } catch let error as BehavioralBiometricError {
                await send(.onError(error))
            }
        }
    }
}
