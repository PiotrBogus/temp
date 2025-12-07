import Labels
import UIComponents
import UIKit

public struct BehavioralBiometricBottomSheetDataBuilder {
    private struct Constants {
        static let behavioralBiometricContentViewSpacing: CGFloat = 18
        static let behavioralBiometricContentViewHorizontalPadding: CGFloat = 16
    }

    public static func buildBehavioralBiometricDisableExplanationData(
        onDefaultDismiss: (() -> Void)?
    ) -> BottomSheetData {
        BottomSheetData(
            headerText: .labels.BehavioralBiometric_CancelAgreementsBottomSheet_lbl_Title.localized,
            contentText: .labels.BehavioralBiometric_CancelAgreementsBottomSheet_lbl_Description.localized,
            onDefaultDismiss: onDefaultDismiss
        )
    }

    public static func buildBehavioralBiometricDisabledData(
        onPrimaryButtonTapped: ((BottomSheetController) -> Void)?,
        onSecondaryButtonTapped: ((BottomSheetController) -> Void)?,
        onDefaultDismiss: (() -> Void)?
    ) -> BottomSheetData {
        let contentView = makeBehavioralBiometricContentView()

        return BottomSheetData(
            headerText: .labels.BehavioralBiometric_TurnOffBehavioralBiometricBottomSheet_lbl_Title.localized,
            contentView: contentView,
            primaryTitle: .labels.BehavioralBiometric_TurnOffBehavioralBiometricBottomSheet_btn_Yes.localized,
            secondaryTitle: .labels.BehavioralBiometric_TurnOffBehavioralBiometricBottomSheet_btn_No.localized,
            onPrimaryButtonTapped: onSecondaryButtonTapped,
            onSecondaryButtonTapped: onPrimaryButtonTapped,
            onDefaultDismiss: onDefaultDismiss
        )
    }

    private static func makeBehavioralBiometricContentView() -> UIView {
        MainActor.assumeIsolated {
            let containerView = UIView()
            let contentStackView = UIStackView()
            contentStackView.axis = .vertical
            contentStackView.spacing = Constants.behavioralBiometricContentViewSpacing
            let topLabel = Label(.regular(.size16LS22)).multiline()
            topLabel.text = .labels.BehavioralBiometric_TurnOffBehavioralBiometricBottomSheet_lbl_Description.localized
            let bottomLabel = Label(.regular(.size16LS22)).multiline()
            bottomLabel.text = .labels.BehavioralBiometric_TurnOffBehavioralBiometricBottomSheet_lbl_Info.localized
            let contentMessageView = ContentMessageView(icon: .critical)
            contentMessageView.subtitle = .labels.BehavioralBiometric_TurnOffBehavioralBiometricBottomSheet_lbl_ContentMessage.localized
            contentStackView.addArrangedSubviews([
                topLabel,
                contentMessageView,
                bottomLabel
            ])
            containerView.addSubview(contentStackView)
            contentStackView.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview().inset(Constants.behavioralBiometricContentViewHorizontalPadding)
                $0.top.bottom.equalToSuperview()
            }
            return containerView
        }
    }
}
