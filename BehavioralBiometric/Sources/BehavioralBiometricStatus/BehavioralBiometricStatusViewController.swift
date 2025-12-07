import Assembly
import ComposableArchitecture
import Foundation
import Labels
import SwinjectAutoregistration
import SwiftUI

public final class BehavioralBiometricStatusViewController: UIViewController {
    private let bottomSheetPresenter: BehavioralBiometricBottomSheetPresenting = IKOAssembler.resolver~>
    private let store: StoreOf<BehavioralBiometricStatusReducer>
    private let errorPresenter: BehavioralBiometricErrorNavigationPresenting = IKOAssembler.resolver~>
    private let navigationProvider: BehavioralBiometricExtendedNavigationProviding = IKOAssembler.resolver~>

    public init() {
        self.store = Store(initialState: BehavioralBiometricStatusReducer.State()) { BehavioralBiometricStatusReducer()
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        setUpHoldsViewController()

        observe { [weak self] in
            self?.updateNavigation()
        }
        store.send(.onAppear)
    }

    // MARK: - Private

    private func setUpHoldsViewController() {
        let behavioralBiometricStatusView = BehavioralBiometricStatusView(store: store)
        let hostingViewController = UIHostingController(rootView: behavioralBiometricStatusView)
        embed(hostingViewController, in: view)
        hostingViewController.didMove(toParent: self)
    }

    private func setUpNavigationBar() {
        configureNavigationHeader(title: .labels.MyData_DetailsAdditionalSecurity_lbl_HeaderTitle.localized)
        setUpBackButton()
    }

    private func updateNavigation() {
        switch store.destination {
        case .mPinBottomSheet:
            presentMPinBottomSheet()
        case .disableBehavioralBiometric:
            presentDisableBehavioralBiometric()
        case .successfullDisableBehavioralBiometric:
            presentSuccessfullDisableBehavioralBiometric()
        case .enableBehavioralBiometric:
            presentAgreements()
        case .error:
            presentErrorScreen()
        case .explanation:
            presentExplanationScreen()
        case .none:
            return
        }
        store.send(.onResetDestination)
    }

    private func presentMPinBottomSheet() {
        bottomSheetPresenter.presentMPINBottomSheet(on: self) { [weak self] mPin in
            self?.dismiss(animated: true) {
                self?.store.send(.onReceiveMPin(mPin))
            }
        }
    }

    private func presentErrorScreen() {
        errorPresenter.presentError(
            on: self,
            header: .labels.Generic_Error_lbl_Header.localized,
            title: .labels.Generic_Error_lbl_Subtitle.localized,
            subtitle: nil,
            okButtonTitle: .labels.Generic_lbl_Ok.localized,
            okButtonBehex: .IKOBehexEventIdUnknown,
            okButtonHandler: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.navigationController?.popViewController(animated: true)
                }
            },
            tryAgainButtonTitle: .labels.Exception_ServerError_btn_Refresh.localized,
            tryAgainButtonBehex: .IKOBehexEventIdUnknown,
            tryAgainButtonHandler: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.store.send(.onTryAgain)
                }
            },
            viewShowBehex: .IKOBehexEventIdUnknown
        )
    }

    private func presentExplanationScreen() {
        let isPrimaryButtonVisible = !store.isBehavioralBiometricEnabled
        navigationProvider.pushBehavioralBiometricExplanationViewController(
            on: self,
            isPrimaryButtonVisible: isPrimaryButtonVisible
        )
    }

    private func presentDisableBehavioralBiometric() {
        let bottomSheetData = BehavioralBiometricBottomSheetDataBuilder.buildBehavioralBiometricDisabledData(
            onPrimaryButtonTapped: {[weak self] _ in
                self?.dismiss(animated: true)
            },
            onSecondaryButtonTapped: { [weak self] _ in
                self?.dismiss(animated: true) {
                    self?.store.send(.onDisableBehavioralBiometric)
                }
            },
            onDefaultDismiss: { [weak self] in
                self?.dismiss(animated: true)
            }
        )

        navigationProvider.presentBehavioralBiometricBottomSheet(
            on: self,
            bottomSheetData: bottomSheetData
        )
    }

    private func presentAgreements() {
        navigationProvider.pushBehavioralBiometricAgreementsViewController(on: self)
    }

    private func presentSuccessfullDisableBehavioralBiometric() {
        navigationProvider.presentDisableBehavioralBiometricSuccessScreen(on: self)
    }
}
