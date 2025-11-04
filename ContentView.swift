import DesignSystemTokens
import UIKit

public final class MultiCheckbox: UIView {
    // MARK: - Style

    public enum State {
        case normal
        case error
    }

    private enum Constants {
        static let errorLabelStyle: UIFont.Style = .regular(.size14LS18, color: .ikoRed100)
        static let contentMessageSpacing: CGFloat = 14
        static let contentMessageIndexOffset = 1
        static let spacing: CGFloat = 12
    }

    // MARK: - Public

    public private(set) var state: State = .normal

    public var isEnabled = true {
        didSet {
            if !isEnabled { hideErrors() }
            mainCheckbox.isEnabled = isEnabled
            for item in checkboxes { item.checkbox.isEnabled = isEnabled }
        }
    }

    public var onCheckedChanged: (([Int]) -> Void)?
    public var checkedIndices: [Int] {
        checkboxes
            .enumerated()
            .filter { _, item in item.checkbox.isChecked }
            .map { index, _ in index }
    }

    public var onNeedsToPresentBottomSheet: ((BottomSheetController) -> Void)?
    public var onPlainCheckboxActionButtonTap: ((String) -> Void)?

    public var isTopSeparatorHidden: Bool {
        get { mainCheckbox.isTopSeparatorHidden }
        set { mainCheckbox.isTopSeparatorHidden = newValue }
    }

    public var isBottomSeparatorHidden: Bool {
        get { checkboxes.last?.checkbox.isBottomSeparatorHidden ?? true }
        set { checkboxes.last?.checkbox.isBottomSeparatorHidden = newValue }
    }

    // MARK: - Private

    private let mainCheckbox: Checkbox
    private let stackView: UIStackView
    private let checkboxesStackView: UIStackView
    private let style: CheckboxStyle
    private let accessibilityLabelsProvider: DesignSystemLabelsProviding.Accessibility = DesignSystem.labels.accessibilityLabels
    private let errorLabel = Label(Constants.errorLabelStyle)
        .multiline()
        .hide()

    private let errorContainer: InsetContainer<Label>

    private var checkboxes: [(identifier: String, checkbox: CheckboxTraits)] = []

    private var checkboxesWithErrorCount: Int {
        checkboxes.count(where: { $0.checkbox.hasError })
    }

    // MARK: - Constructors

    public init(titleText: String, options: [CheckboxOption], style: CheckboxStyle = .clear) {
        let shouldCreate = MultiCheckbox.shouldCreate(with: options)
        assert(shouldCreate.canCreate, shouldCreate.message)
        mainCheckbox = Checkbox(controlStyle: .single(style))
        mainCheckbox.text = "__\(titleText)__"
        checkboxesStackView = UIStackView(spacing: style.checkboxesSpacing, axis: .vertical)
        stackView = UIStackView(spacing: Constants.spacing, axis: .vertical)
        self.style = style
        errorContainer = InsetContainer(contentView: errorLabel, insets: style.errorInsets)
        super.init(frame: .zero)
        setUpView(with: options)
        setUpAction()
        setUpConstraints()
        setUpAccessibility()
    }

    required init?(coder: NSCoder) { nil }

    public func insertContentMessageBelowTitle(_ contentMessage: ContentMessageView) {
        checkboxesStackView.insertArrangedSubview(contentMessage, at: Constants.contentMessageIndexOffset)
        checkboxesStackView.setCustomSpacing(Constants.contentMessageSpacing, after: mainCheckbox)
        checkboxesStackView.setCustomSpacing(Constants.contentMessageSpacing, after: contentMessage)
        updateCheckboxesAccessibilityContainer()
    }

    public func insertContentMessage(_ contentMessage: ContentMessageView, afterCheckboxIdentifier identifier: String) {
        guard
            let checkboxOption = (checkboxes.first { $0.identifier == identifier }),
            let index = checkboxesStackView.arrangedSubviews.firstIndex(of: checkboxOption.checkbox)
        else { return }
        checkboxesStackView.insertArrangedSubview(contentMessage, at: index + Constants.contentMessageIndexOffset)
        checkboxesStackView.setCustomSpacing(Constants.contentMessageSpacing, after: checkboxOption.checkbox)
        checkboxesStackView.setCustomSpacing(Constants.contentMessageSpacing, after: contentMessage)
        updateCheckboxesAccessibilityContainer()
    }

    // MARK: - Layout

    private static func shouldCreate(with options: [CheckboxOption]) -> (canCreate: Bool, message: String) {
        if
            !Dictionary(grouping: options, by: \.identifier)
                .filter({ $1.count > 1 })
                .isEmpty
        {
            return (false, "Checkbox options identifier duplicates")
        }
        return (true, .empty)
    }

    private func setUpView(with options: [CheckboxOption]) {
        errorContainer.isHidden = true
        checkboxesStackView.backgroundColor = style.color

        checkboxes = options.map { ($0.identifier, $0.makeCheckbox(with: .multi(style))) }
        checkboxesStackView.addArrangedSubviews(
            [mainCheckbox] +
                checkboxes.map { $0.checkbox }
        )
        stackView.addArrangedSubviews([
            checkboxesStackView,
            errorContainer,
        ])
        addSubview(stackView)
        setUpSeparators()
    }

    private func setUpSeparators() {
        guard style.shouldShowSeparators else { return }
        isTopSeparatorHidden = true
        isBottomSeparatorHidden = false
    }

    private func setUpConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Error

    public func showError(_ message: String) {
        state = .error
        errorLabel.text = message
        showErrorContainer(true)
    }

    public func showErrorInMainCheckbox() {
        state = .error
        mainCheckbox.showError(nil)
    }

    public func showError(_ message: String?, for identifier: String) {
        guard let checkbox = checkbox(for: identifier) else { return }
        state = .error
        checkbox.showError(message)
    }

    public func hideError() {
        if checkboxesWithErrorCount == .zero {
            state = .normal
        }
        showErrorContainer(false)
    }

    public func hideErrorInMainCheckbox() {
        mainCheckbox.hideError()
        if errorContainer.isHidden, checkboxesWithErrorCount == .zero {
            state = .normal
        }
    }

    public func hideError(for identifier: String) {
        guard let checkbox = checkbox(for: identifier) else { return }
        checkbox.hideError()
        if errorContainer.isHidden, checkboxesWithErrorCount == .zero {
            state = .normal
        }
    }

    public func hideErrors() {
        state = .normal
        showErrorContainer(false)
        mainCheckbox.hideError()
        for item in checkboxes { item.checkbox.hideError() }
    }

    private func showErrorContainer(_ show: Bool) {
        errorContainer.isHidden = !show
        if !show {
            errorLabel.text = nil
        }
    }

    private func checkbox(for identifier: String) -> CheckboxTraits? {
        checkboxes
            .first { $0.identifier == identifier }
            .map { $0.checkbox }
    }

    // MARK: - Actions

    private func setUpAction() {
        mainCheckbox.onCheckedChanged = { [weak self] checked in
            guard let self else { return }
            for item in checkboxes { item.checkbox.isChecked = checked }
            onCheckedChanged?(checkedIndices)
        }

        checkboxes.forEach { [weak self] in
            $0.checkbox.onCheckedChanged = { [weak self] _ in
                guard let self else { return }
                onCheckedChanged?(checkedIndices)
                updateMainCheckboxCheck()
            }

            self?.setUpExpandableActionIfNeeded(for: $0.checkbox)
            self?.setUpCustomActionIfNeeded(for: $0.checkbox, identifier: $0.identifier)
        }
    }

    private func setUpExpandableActionIfNeeded(for checkbox: CheckboxTraits) {
        guard let expandableCheckbox = checkbox as? ExpandableCheckbox else { return }
        expandableCheckbox.onNeedsToPresentBottomSheet = { [weak self] bottomSheet in
            self?.onNeedsToPresentBottomSheet?(bottomSheet)
        }
    }

    private func setUpCustomActionIfNeeded(for checkbox: CheckboxTraits, identifier: String) {
        guard let plainCheckbox = checkbox as? Checkbox else { return }
        plainCheckbox.onCustomActionButtonTap = { [weak self] in
            self?.onPlainCheckboxActionButtonTap?(identifier)
        }
    }

    private func updateMainCheckboxCheck() {
        mainCheckbox.isChecked = checkboxes.allSatisfy { $0.checkbox.isChecked }
    }

    // MARK: - Accessibility

    private func setUpAccessibility() {
        isAccessibilityElement = false
        accessibilityElements = [showErrorContainer, checkboxesStackView]
        checkboxesStackView.accessibilityContainerType = .list
        updateCheckboxesAccessibilityContainer()
    }

    private func updateCheckboxesAccessibilityContainer() {
        checkboxesStackView.accessibilityElements = checkboxesStackView.arrangedSubviews
    }
}

extension CheckboxStyle {
    fileprivate enum Constants {
        static let spacing: CGFloat = 16
    }

    fileprivate var checkboxesSpacing: CGFloat {
        switch self {
        case .whiteBackground: .zero
        case .clear: Constants.spacing
        }
    }

    fileprivate var errorInsets: UIEdgeInsets {
        switch self {
        case .whiteBackground: .init(top: .zero, left: Constants.spacing, bottom: .zero, right: .zero)
        case .clear: .zero
        }
    }
}
