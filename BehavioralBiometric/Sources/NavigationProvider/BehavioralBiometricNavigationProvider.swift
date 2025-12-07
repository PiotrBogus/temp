import Assembly
import DesignSystemUIKit
import Foundation
import Labels
import UIComponents
import UIKit
import SwinjectAutoregistration

@objc
public class BehavioralBiometricNavigationProvider: NSObject, BehavioralBiometricExtendedNavigationProviding {

    @objc public override init() {}
    
    @MainActor
    public func presentDisableBehavioralBiometricSuccessScreen(
        on viewController: UIViewController
    ) {
        let resultViewController = IKOResultViewController(
            assetName: IKO_ANIMATION_ICON_RESULT_SUCCESS,
            title: .labels.BehavioralBiometric_TurnOffResultScreen_lbl_Title.localized,
            subtitle: .labels.BehavioralBiometric_TurnOffResultScreen_lbl_Description.localized,
            resultType: .IKOConfirmationResultSuccess,
            buttonTitle: .labels.BehavioralBiometric_TurnOffResultScreen_btn_Restart.localized,
            buttonHandler: { _ in
                viewController.dismiss(animated: true) {
                    let logoutPerformer: BehavioralBiometricLogoutPerforming = IKOAssembler.resolver~>
                    logoutPerformer.performLogout()
                }
            },
            cancelButtonResultHandler: { _ in }
        )
        resultViewController?.showCloseButton = false
        viewController.present(resultViewController!, animated: true)
    }

    @MainActor
    @objc public func createBehavioralBiometricExplanationViewController(
        isPrimaryButtonVisible: Bool
    ) -> IKOBaseViewController {
        BehavioralBiometricExplanationViewController(isPrimaryButtonVisible: isPrimaryButtonVisible)
    }

    @MainActor
    @objc public func pushBehavioralBiometricExplanationViewController(
        on viewController: UIViewController,
        isPrimaryButtonVisible: Bool
    ) {
        let explanationViewController = createBehavioralBiometricExplanationViewController(isPrimaryButtonVisible: isPrimaryButtonVisible)
        viewController.navigationController?.pushViewController(explanationViewController, animated: true)
    }

    @MainActor
    @objc public func createBehavioralBiometricAgreementsViewController() -> IKOBaseViewController {
        BehavioralBiometricAgreementsViewController()
    }

    @MainActor
    @objc public func pushBehavioralBiometricAgreementsViewController(
        on viewController: UIViewController
    ) {
        let agreementsViewController = BehavioralBiometricAgreementsViewController()
        viewController.navigationController?.pushViewController(agreementsViewController, animated: true)
    }

    @MainActor
    public func pushBehavioralBiometricFAQView(
        on viewController: UIViewController
    ) {
        let faqViewController = BehavioralBiometricFAQViewController()
        viewController.navigationController?.pushViewController(faqViewController, animated: true)
    }

    @MainActor
    public func presentBehavioralBiometricBottomSheet(
        on viewController: UIViewController,
        bottomSheetData: BottomSheetData
    ) {
        var bottomSheetController: BottomSheetController?
        if let contentText = bottomSheetData.contentText {
            bottomSheetController = BottomSheetController(
                isDismissable: true,
                contentText: contentText,
                headerText: bottomSheetData.headerText,
                primaryTitle: bottomSheetData.primaryTitle,
                secondaryTitle: bottomSheetData.secondaryTitle
            )
        } else if let contentView = bottomSheetData.contentView {
            bottomSheetController = BottomSheetController(
                isDismissable: true,
                contentView: contentView,
                headerText: bottomSheetData.headerText,
                primaryTitle: bottomSheetData.primaryTitle,
                secondaryTitle: bottomSheetData.secondaryTitle
            )
        }

        guard let bottomSheetController else { return }

        bottomSheetController.onPrimaryButtonTapped = bottomSheetData.onPrimaryButtonTapped
        bottomSheetController.onSecondaryButtonTapped = bottomSheetData.onSecondaryButtonTapped
        bottomSheetController.onDefaultDismissCompletion = bottomSheetData.onDefaultDismiss
        BottomSheetPresenter().present(bottomSheetController, on: viewController)
    }

    @MainActor
    public func pushEnableBehavioralBiometricSuccessScreen(
        on viewController: UIViewController
    ) {
        guard let resultViewController = IKOResultViewController(
            assetName: IKO_ANIMATION_ICON_RESULT_SUCCESS,
            title: .labels.BehavioralBiometric_TurnOnResultScreen_lbl_Title.localized,
            subtitle: .labels.BehavioralBiometric_TurnOnResultScreen_lbl_Description.localized,
            resultType: .IKOConfirmationResultSuccess,
            buttonTitle: .labels.BehavioralBiometric_TurnOnResultScreen_btn_Ok.localized,
            buttonHandler: { _ in
                viewController.navigationController?.popToRootViewController(animated: true)
            },
            cancelButtonResultHandler: { _ in
                viewController.navigationController?.popToRootViewController(animated: true)
            }
        ) else { return }
        viewController.navigationController?.pushViewController(resultViewController, animated: true)
    }
}
