import UIComponents
import Assets
import IKOCommon
import Behex
import Highways
import ParkingPlaces
import TransportTickets

extension IKOMainAssembly {

    @objc
    func behavioralBiometricTeaserViewController() -> IKOTeaserWithBlueAndWhiteButtonViewController {
        let controller = IKOTeaserWithBlueAndWhiteButtonViewController(
            title: IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_lbl_Title,
            subtitle: IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_lbl_Subtitle,
            blueButtonTitle: IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_btn_OK,
            whiteButtonTitle: IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_btn_ActivationBenefits,
            image: Assets.imageNamed(IKOImages.IKO_TEASER_MOBILEAUTHORIZATION)
        )

        weak var weakController = controller
        weak var weakSelf = self

        controller.blueButtonHandler = {
            guard let strongSelf = weakSelf,
                  let strongController = weakController else { return }

            IKOAssembler.resolveBehex().register(withEvent: Activation_Required_btn_Activate)

            if IKORestrictionsManager.shared().isSignatureMissing {
                strongController.modalLayerViewController.dismissWithCompletion {
                    let modalLayer = IKOAssembler
                        .resolveIKOMainAssemblyRestrictions()
                        .signatureMissingModalLayerViewController()

                    modalLayer.show(
                        on: strongSelf.controllerToPresentModalOn().navigationController!,
                        dismissCompletion: nil
                    )
                }
            } else {
                let activationVC = IKOAssembler
                    .resolveIKOMainAssemblyActivation()
                    .activationNavigationViewController(withDelegate: nil)

                strongSelf.controllerToPresentModalOn().present(
                    activationVC,
                    animated: true,
                    transitionType: IKORouterTransitionType.standard,
                    completion: nil
                )

                strongController.modalLayerViewController.dismiss()
            }
        }

        controller.whiteButtonHandler = {
            guard let strongSelf = weakSelf,
                  let strongController = weakController else { return }

            let notActiveVC = IKOAssembler
                .resolveIKOMainAssemblyRestrictions()
                .notActiveViewController(
                    withOriginalViewController: strongSelf.controllerToPresentModalOn().navigationController
                )

            let navigation = IKOAssembler.resolveIKOBaseNavigationController(withRoot: notActiveVC)

            strongSelf.controllerToPresentModalOn().present(
                navigation,
                animated: true,
                transitionType: IKORouterTransitionType.standard,
                completion: nil
            )

            strongController.modalLayerViewController.dismiss()
        }

        return controller
    }
}
