import Foundation
import UIKit
import UIComponents

@objc
public protocol BehavioralBiometricObjectiveCNavigationProviding: NSObjectProtocol {
    @MainActor @objc func presentDisableBehavioralBiometricSuccessScreen(
        on viewController: UIViewController
    )
    @MainActor @objc func createBehavioralBiometricExplanationViewController(
        isPrimaryButtonVisible: Bool
    ) -> IKOBaseViewController
    @MainActor @objc func pushBehavioralBiometricExplanationViewController(
        on viewController: UIViewController,
        isPrimaryButtonVisible: Bool
    )
    @MainActor @objc func createBehavioralBiometricAgreementsViewController() -> IKOBaseViewController
    @MainActor @objc func pushBehavioralBiometricAgreementsViewController(
        on viewController: UIViewController
    )
}



- (void)performNavigateToBehavioralBiometricAgreements:(UIViewController *)controller  {
    BehavioralBiometricObjectiveCNavigationProviding *navigationProvider = [IKOAssembler resolveBehavioralBiometricNavigationProvider];
    [navigationProvider pushBehavioralBiometricAgreementsViewControllerOn:controller];
}
