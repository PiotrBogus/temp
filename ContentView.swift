import Assembly
import Dependencies
import DependenciesMacros
import UIKit
import UIComponents

struct BehavioralBiometricErrorViewControllerModel: Sendable {
    let viewController: UIViewController
    let header: String
    let title: String
    let okButtonTitle: String
    let okButtonBehex: IKOBehexEventId
    let okButtonHandler: @Sendable () -> Void
    let tryAgainButtonTitle: String
    let tryAgainButtonBehex: IKOBehexEventId
    let tryAgainButtonHandler: @Sendable () -> Void
    let viewShowBehex: IKOBehexEventId
}

struct BehavioralBiometricErrorNavigationProvider: DependencyKey {
    var presentErrorViewController: @MainActor @Sendable (BehavioralBiometricErrorViewControllerModel) -> Void

    static var liveValue: BehavioralBiometricErrorNavigationProvider = {
        BehavioralBiometricErrorNavigationProvider(
            presentErrorViewController: { model in
                guard let contentView = IKOResultContentView(
                    assetName: IKO_ANIMATION_ICON_RESULT_ERROR,
                    title: model.title,
                    subtitle: nil,
                    token: nil,
                    resultType: .IKOConfirmationResultError
                ) else { return }

                let bottomView = IKOBlueAndWhiteButtonBottomView(
                    blueButtonTitle: model.tryAgainButtonTitle,
                    whiteButtonTitle: model.okButtonTitle
                )
                bottomView?.whiteButton?.iko_addEventHandler({ _ in
                    IKOAssembler.resolveBehex()?.register(event: model.okButtonBehex)
                    model.okButtonHandler()
                }, forControlEvents: .primaryActionTriggered)
                bottomView?.blueButton?.iko_addEventHandler({ _ in
                    IKOAssembler.resolveBehex()?.register(event: model.tryAgainButtonBehex)
                    model.tryAgainButtonHandler()
                }, forControlEvents: .primaryActionTriggered)

                guard let controller = IKOResultViewController(
                    contentView: contentView,
                    bottomView: bottomView,
                    cancelButtonResultHandler: { _ in
                        IKOAssembler.resolveBehex()?.register(event: model.okButtonBehex
                        )
                        model.okButtonHandler()
                    }) else { return }

                controller.resultNavigationBarTitle = model.header
                controller.behexEventId = model.viewShowBehex
                model.viewController.present(controller, animated: true)
            }
        )
    }()
}

extension DependencyValues {
    var behavioralBiometricErrorNavigationProvider: BehavioralBiometricErrorNavigationProvider {
        get { self[BehavioralBiometricErrorNavigationProvider.self] }
        set { self[BehavioralBiometricErrorNavigationProvider.self] = newValue }
    }
}
