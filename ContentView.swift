import DesignSystemUIKit

public final class BehavioralBiometricAgreementsView: UIView {
        private struct Constants {
            static let headerPadding: CGFloat = 14
            static let headerTopPadding: CGFloat = 24
            static let headerBottomPadding: CGFloat = 18
            static let defaultPadding: CGFloat = 16
        }

    private let headerStackView = UIStackView(axis: .vertical)
    private let headerTitle: Label = .init(.regular(.size18LS22))
    private let bulletPoint: Label = .init(.regular(.size16LS22))
    private let multiCheckbox = MultiCheckbox(
        titleText: "Zaznacz wszystkie",
        options: [
            .init(
                identifier: UUID().uuidString,
                style: .expandable(option: .init(
                    text: "Zgoda na udostępnienie mojego numeru PESEL albo numer paszportu przez PKO Bank Polski firmie Biuro Informacji Kredytowej (BIK).",
                    textToExpand: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry’s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containin"
                ))
            ),
            .init(
                identifier: UUID().uuidString,
                style: .expandable(option: .init(
                    text: "Zgoda na przetwarzanie moich danych osobowych przez PKO Bank Polski i firmę Biuro Informacji Kredytowej (BIK).",
                    textToExpand: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry’s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containin",
                ))
            )
        ],
        style: .whiteBackground
    )
    private let contentMessageView = ContentMessageView(icon: .hint)
    private let primaryButtonContainer = UIView(frame: .zero)
    private let primaryButton = PrimaryButton(title: "Włącz dodatkowe zabezpieczenia")
    private let mainContainer = UIView(frame: .zero)
    private let scrollView = UIScrollView()
    private let presentBottomSheet: (BottomSheetController) -> Void

    init(
        presentBottomSheet: @escaping (BottomSheetController) -> Void
    ) {
        self.presentBottomSheet = presentBottomSheet
        super.init(frame: .zero)

        setup()
        setupViewHierarchy()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        headerStackView.spacing = Constants.headerPadding
        headerTitle.multiline()
        headerTitle.text = "Wzmocnij bezpieczeństwo swoich pieniędzy"
        bulletPoint.multiline()
        bulletPoint.text = "* Ochrona jest darmowa i po udzieleniu zgód nie musisz nic więcej robić./n* Sprawdzamy, czy to na pewno Ty używasz aplikacji IKO."
        contentMessageView.title = "Zgody są dobrowolne i możesz je odwołać w dowolnym momencie."
        contentMessageView.buttonTitle = "Dowiedz się więcej o odwołaniu zgód"
        contentMessageView.onTap = {
            // TO DO
        }
        multiCheckbox.onCheckedChanged = { selectedCheckbox in
            print(selectedCheckbox)
        }
        multiCheckbox.onNeedsToPresentBottomSheet = presentBottomSheet
        multiCheckbox.onPlainCheckboxActionButtonTap = { title in
            print(title)
        }
    }

    private func setupViewHierarchy() {
        headerStackView.addArrangedSubviews([
            headerTitle,
            bulletPoint
        ])
        scrollView.addSubview(mainContainer)
        mainContainer.addSubviews([
            headerStackView,
            multiCheckbox,
            contentMessageView
        ])
        primaryButtonContainer.addSubview(primaryButton)
        addSubviews([
            scrollView,
            primaryButtonContainer
        ])
    }

    private func setupConstraints() {
        mainContainer.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        headerStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.headerTopPadding)
            $0.leading.equalToSuperview().offset(Constants.defaultPadding)
            $0.trailing.equalToSuperview().inset(Constants.defaultPadding)
        }

        multiCheckbox.snp.makeConstraints {
            $0.top.equalTo(headerStackView.snp.bottom).offset(Constants.headerBottomPadding)
            $0.leading.trailing.equalToSuperview()
        }

        contentMessageView.snp.makeConstraints {
            $0.top.equalTo(multiCheckbox.snp.bottom).offset(Constants.defaultPadding)
            $0.leading.equalToSuperview().offset(Constants.defaultPadding)
            $0.trailing.equalToSuperview().inset(Constants.defaultPadding)
        }
        scrollView.snp.makeConstraints {
            $0.top.trailing.leading.equalToSuperview()
        }

        primaryButtonContainer.snp.makeConstraints {
            $0.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(scrollView.snp.bottom).offset(Constants.defaultPadding)
        }

        primaryButton.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Constants.defaultPadding)
        }
    }
}
