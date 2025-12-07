import DesignSystemUIKit
import Foundation
import Labels
import UIKit
import SnapKit

public final class BehavioralBiometricAgreementsView: UIView {
        private struct Constants {
            static let headerPadding: CGFloat = 14
            static let headerTopPadding: CGFloat = 24
            static let headerBottomPadding: CGFloat = 18
            static let defaultPadding: CGFloat = 16
            static let animationDuration: TimeInterval = 0.3
        }

    private let headerStackView = UIStackView(axis: .vertical)
    private let headerTitle: Label = .init(.regular(.size18LS22))
    private let bulletPoint: Label = .init(.regular(.size16LS22))
    private let multiCheckboxStackView = UIStackView()
    private var multiCheckbox: MultiCheckbox?
    private let contentMessageView = ContentMessageView(icon: .hint)
    private let primaryButtonContainer = UIView(frame: .zero)
    private let primaryButton = PrimaryButton(title: .labels.BehavioralBiometric_AgreementsScreen_btn_TurnOn.localized)
    private let mainContainer = UIView(frame: .zero)
    private let scrollView = UIScrollView()
    private let onCheckedChanged: (([Int]) -> Void)
    private let onNeedsToPresentBottomSheet: (BottomSheetController) -> Void
    private let onPrimaryButtonTap: () -> Void
    private let onMoreInformationTap: () -> Void
    private var loaderView: ContentLoaderView?

    init(
        onCheckedChanged: @escaping (([Int]) -> Void),
        onNeedsToPresentBottomSheet: @escaping (BottomSheetController) -> Void,
        onPrimaryButtonTap: @escaping () -> Void,
        onMoreInformationTap: @escaping () -> Void
    ) {
        self.onCheckedChanged = onCheckedChanged
        self.onNeedsToPresentBottomSheet = onNeedsToPresentBottomSheet
        self.onPrimaryButtonTap = onPrimaryButtonTap
        self.onMoreInformationTap = onMoreInformationTap
        super.init(frame: .zero)

        setup()
        setupViewHierarchy()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAgreementsMultiCheckbox(options: [CheckboxOption]) {
        multiCheckbox = MultiCheckbox(
            titleText: .labels.BehavioralBiometric_AgreementsScreen_btn_CheckAllAgreements.localized,
            options: options,
            style: .whiteBackground
        )
        multiCheckbox?.onCheckedChanged = onCheckedChanged
        multiCheckbox?.onNeedsToPresentBottomSheet = onNeedsToPresentBottomSheet
        multiCheckboxStackView.removeAllArrangedSubviews()
        multiCheckboxStackView.addArrangedSubview(multiCheckbox!)
    }

    func updateAgreementsMultiCheckboxErrorsVisibility(ids: [String]) {
        multiCheckbox?.hideErrors()
        ids.forEach {
            multiCheckbox?.showError("[Test] Wymagana zgoda", for: $0)
        }
    }

    func updateLoaderView(isVisible: Bool) {
        if isVisible {
            loaderView = ContentLoaderView()
            addSubview(loaderView!)
            loaderView?.snp.makeConstraints {
                $0.centerX.centerY.equalToSuperview()
            }
            loaderView?.isLoaderVisible = isVisible
        } else {
            loaderView?.removeFromSuperview()
            loaderView = nil
        }
        layoutIfNeeded()
        UIView.animate(withDuration: Constants.animationDuration) { [weak self] in
            self?.scrollView.alpha = isVisible ? 0 : 1
            self?.primaryButton.alpha = isVisible ? 0 : 1
            self?.layoutIfNeeded()
        }
    }

    private func setup() {
        self.backgroundColor = .ikoBlue0
        primaryButton.onTap = onPrimaryButtonTap
        headerStackView.spacing = Constants.headerPadding
        headerTitle.multiline()
        headerTitle.text = .labels.BehavioralBiometric_AgreementsScreen_lbl_HeaderTitle.localized
        bulletPoint.multiline()
        bulletPoint.text = .labels.BehavioralBiometric_AgreementsScreen_lbl_HeaderDescription.localized
        contentMessageView.title = .labels.BehavioralBiometric_AgreementsScreen_lbl_ContentMessageText.localized
        contentMessageView.buttonTitle = .labels.BehavioralBiometric_AgreementsScreen_btn_ContentMessageMoreInfo.localized
        contentMessageView.onTap = onMoreInformationTap
    }

    private func setupViewHierarchy() {
        headerStackView.addArrangedSubviews([
            headerTitle,
            bulletPoint
        ])
        scrollView.addSubview(mainContainer)
        mainContainer.addSubviews([
            headerStackView,
            multiCheckboxStackView,
            contentMessageView
        ])
        primaryButtonContainer.addSubview(primaryButton)
        addSubviews([
            scrollView,
            primaryButtonContainer
        ])
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(primaryButtonContainer.snp.top)
        }

        mainContainer.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
            $0.bottom.equalTo(contentMessageView.snp.bottom).offset(32)
        }

        headerStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.headerTopPadding)
            $0.leading.equalToSuperview().offset(Constants.defaultPadding)
            $0.trailing.equalToSuperview().inset(Constants.defaultPadding)
        }

        multiCheckboxStackView.snp.makeConstraints {
            $0.top.equalTo(headerStackView.snp.bottom).offset(Constants.headerBottomPadding)
            $0.leading.trailing.equalToSuperview().inset(Constants.defaultPadding)
        }

        contentMessageView.snp.makeConstraints {
            $0.top.equalTo(multiCheckboxStackView.snp.bottom).offset(Constants.defaultPadding)
            $0.leading.equalToSuperview().offset(Constants.defaultPadding)
            $0.trailing.equalToSuperview().inset(Constants.defaultPadding)
        }

        primaryButtonContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottomMargin)
        }

        primaryButton.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Constants.defaultPadding)
        }
    }
}
