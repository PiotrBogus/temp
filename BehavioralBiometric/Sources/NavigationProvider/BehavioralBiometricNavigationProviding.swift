import Foundation
import UIComponents
import UIKit

public protocol BehavioralBiometricNavigationProviding {
    @MainActor func pushBehavioralBiometricFAQView(
        on viewController: UIViewController
    )
    @MainActor func presentBehavioralBiometricBottomSheet(
        on viewController: UIViewController,
        bottomSheetData: BottomSheetData
    )
    @MainActor func pushEnableBehavioralBiometricSuccessScreen(
        on viewController: UIViewController
    )
}
