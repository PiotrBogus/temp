import Assembly
import UIComponents

public struct BehavioralBiometricErrorNavigationPresenter: BehavioralBiometricErrorNavigationPresenting {
    public init() {}

    @MainActor
    public func presentError(
        on viewController: UIViewController,
        header: String,
        title: String,
        subtitle: String?,
        okButtonTitle: String,
        okButtonBehex: IKOBehexEventId,
        okButtonHandler: @escaping () -> Void,
        tryAgainButtonTitle: String,
        tryAgainButtonBehex: IKOBehexEventId,
        tryAgainButtonHandler: @escaping () -> Void,
        viewShowBehex: IKOBehexEventId
    ) {
        guard let contentView = IKOResultContentView(
            assetName: IKO_ANIMATION_ICON_RESULT_ERROR,
            title: title,
            subtitle: subtitle,
            token: nil,
            resultType: .IKOConfirmationResultError
        ) else { return }

        let bottomView = IKOBlueAndWhiteButtonBottomView(
            blueButtonTitle: tryAgainButtonTitle,
            whiteButtonTitle: okButtonTitle
        )
        bottomView?.whiteButton?.iko_addEventHandler({ [okButtonHandler] _ in
            IKOAssembler.resolveBehex()?.register(event: okButtonBehex)
            okButtonHandler()
        }, forControlEvents: .primaryActionTriggered)
        bottomView?.blueButton?.iko_addEventHandler({ [tryAgainButtonHandler] _ in
            IKOAssembler.resolveBehex()?.register(event: tryAgainButtonBehex)
            tryAgainButtonHandler()
        }, forControlEvents: .primaryActionTriggered)

        guard let controller = IKOResultViewController(
            contentView: contentView,
            bottomView: bottomView,
            cancelButtonResultHandler: { [okButtonHandler] _ in
                IKOAssembler.resolveBehex()?.register(event: okButtonBehex)
                okButtonHandler()
            }
        ) else { return }

        controller.resultNavigationBarTitle = header
        controller.behexEventId = viewShowBehex
        viewController.present(controller, animated: true)
    }

    @MainActor
    public func presentDefaultError(
        on viewController: UIViewController,
        okButtonHandler: @escaping () -> Void,
        tryAgainButtonHandler: @escaping () -> Void,
    ) {
        presentError(
            on: viewController,
            header: .labels.Generic_Error_lbl_Header.localized,
            title: .labels.Generic_Error_lbl_Subtitle.localized,
            subtitle: nil,
            okButtonTitle: .labels.Generic_lbl_Ok.localized,
            okButtonBehex: .IKOBehexEventIdUnknown,
            okButtonHandler: okButtonHandler,
            tryAgainButtonTitle: .labels.Exception_ServerError_btn_Refresh.localized,
            tryAgainButtonBehex: .IKOBehexEventIdUnknown,
            tryAgainButtonHandler: tryAgainButtonHandler,
            viewShowBehex: .IKOBehexEventIdUnknown
        )
    }
}
