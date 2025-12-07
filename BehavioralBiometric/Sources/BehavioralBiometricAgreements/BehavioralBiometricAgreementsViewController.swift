import Assembly
import ComposableArchitecture
import DesignSystemUIKit
import Foundation
import Labels
import SwinjectAutoregistration
import UIComponents
import UISwiftComponents

public final class BehavioralBiometricAgreementsViewController: IKOBaseViewController, HasCustomView {
    public typealias View = BehavioralBiometricAgreementsView
    private let store: StoreOf<BehavioralBiometricAgreementsReducer>
    private let bottomSheetPresenter: BehavioralBiometricBottomSheetPresenting = IKOAssembler.resolver~>
    private let errorPresenter: BehavioralBiometricErrorNavigationPresenting = IKOAssembler.resolver~>
    private let navigationProvider: BehavioralBiometricNavigationProviding = IKOAssembler.resolver~>

    public init() {
        self.store = Store(initialState: BehavioralBiometricAgreementsReducer.State()) { BehavioralBiometricAgreementsReducer()
        }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        observe { [weak self] in
            guard let self else { return }
            self.updateView()
            self.updateNavigation()
        }
        store.send(.onAppear)
    }

    public override func loadView() {
        view = BehavioralBiometricAgreementsView(
            onCheckedChanged: { [weak self] in
                self?.store.send(.onCheckAgreementsChanged($0))
            },
            onNeedsToPresentBottomSheet: presentBottomSheet,
            onPrimaryButtonTap: { [weak self] in
                self?.store.send(.onPrimaryButtonTap)
            },
            onMoreInformationTap: { [weak self] in
                self?.store.send(.onMoreInformationTap)
            })
    }

    // MARK: - Private

    private func updateView() {
        updateAgreements()
        updateAgreementsErrors()
        castView.updateLoaderView(isVisible: store.isLoading)
    }

    private func updateAgreements() {
        guard !store.didUpdateAgreements,
              !store.agreements.isEmpty else { return }
        castView.updateAgreementsMultiCheckbox(options: store.agreements.compactMap {
            CheckboxOption(
                identifier: $0.id,
                style: .expandable(option: .init(
                    text: $0.textShort,
                    textToExpand: $0.text
                ))
            )
        })
        store.send(.onAgreementsUpdated)
    }

    private func updateAgreementsErrors() {
        castView.updateAgreementsMultiCheckboxErrorsVisibility(ids: store.unselectedMandatoryAgreementsIds)
    }

    private func updateNavigation() {
        switch store.destination {
        case .enabledBehavioralBiometricSuccess:
            pushEnableBehavioralBiometricSuccess()
        case .moreInfo:
            presentDisableBehavioralBiometricExplanationBottomSheet()
        case .mPinBottomSheet:
            presentMPinBottomSheet()
        case .error:
            presentErrorScreen()
        case .none:
            return
        }
        store.send(.onResetNavigation)
    }

    private func setUpNavigationBar() {
        configureNavigationHeader(title: .labels.BehavioralBiometric_AgreementsScreen_lbl_ToolbarTitle.localized)
        setUpBackButton()
    }

    private func presentBottomSheet(bottomSheet: BottomSheetController) {
        DesignSystemUIKit.BottomSheetPresenter().present(bottomSheet, on: self)
    }

    private func presentMPinBottomSheet() {
        bottomSheetPresenter.presentMPINBottomSheet(on: self) { [weak self] mPin in
            self?.dismiss(animated: true) {
                self?.store.send(.onReceiveMPin(mPin))
            }
        }
    }

    private func pushEnableBehavioralBiometricSuccess() {
        navigationProvider.pushEnableBehavioralBiometricSuccessScreen(on: self)
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

    private func presentDisableBehavioralBiometricExplanationBottomSheet() {
        BehavioralBiometricNavigationProvider().presentBehavioralBiometricBottomSheet(
            on: self,
            bottomSheetData: BehavioralBiometricBottomSheetDataBuilder.buildBehavioralBiometricDisableExplanationData() { [weak self] in
                self?.dismiss(animated: true)
            }
        )
    }
}
