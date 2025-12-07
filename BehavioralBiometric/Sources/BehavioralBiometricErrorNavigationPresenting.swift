import UIComponents

public protocol BehavioralBiometricErrorNavigationPresenting {
    @MainActor
    func presentError(
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
    )

    @MainActor
    func presentDefaultError(
        on viewController: UIViewController,
        okButtonHandler: @escaping () -> Void,
        tryAgainButtonHandler: @escaping () -> Void,
    )
}
