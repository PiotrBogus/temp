import Foundation
import IKOCommon
import UIKit

public protocol BehavioralBiometricBottomSheetPresenting {
    func presentMPINBottomSheet(
        on viewController: UIViewController,
        completionHandler: @escaping (IKOUIPin) -> Void
    )
}
