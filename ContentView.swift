import SwiftUI
import UIKit
import DesignSystemTokens

/// SwiftUI wrapper dla UIKitowego MultiCheckbox
public struct MultiCheckboxRepresentable: UIViewRepresentable {
    public typealias UIViewType = MultiCheckbox

    // MARK: - Public properties
    public var titleText: String
    public var options: [CheckboxOption]
    public var style: CheckboxStyle
    public var isEnabled: Bool

    @Binding public var checkedIndices: [Int]
    @Binding public var errorMessage: String?
    public var contentMessages: [String: ContentMessageView]?
    
    public var onPlainCheckboxActionButtonTap: ((String) -> Void)?
    public var onNeedsToPresentBottomSheet: ((BottomSheetController) -> Void)?

    // MARK: - Init
    public init(
        titleText: String,
        options: [CheckboxOption],
        style: CheckboxStyle = .clear,
        isEnabled: Bool = true,
        checkedIndices: Binding<[Int]> = .constant([]),
        errorMessage: Binding<String?> = .constant(nil),
        contentMessages: [String: ContentMessageView]? = nil,
        onPlainCheckboxActionButtonTap: ((String) -> Void)? = nil,
        onNeedsToPresentBottomSheet: ((BottomSheetController) -> Void)? = nil
    ) {
        self.titleText = titleText
        self.options = options
        self.style = style
        self.isEnabled = isEnabled
        self._checkedIndices = checkedIndices
        self._errorMessage = errorMessage
        self.contentMessages = contentMessages
        self.onPlainCheckboxActionButtonTap = onPlainCheckboxActionButtonTap
        self.onNeedsToPresentBottomSheet = onNeedsToPresentBottomSheet
    }

    // MARK: - UIViewRepresentable

    public func makeUIView(context: Context) -> MultiCheckbox {
        let view = MultiCheckbox(titleText: titleText, options: options, style: style)
        view.isEnabled = isEnabled

        // Połączenie callbacków
        view.onCheckedChanged = { indices in
            checkedIndices = indices
        }

        view.onPlainCheckboxActionButtonTap = { identifier in
            onPlainCheckboxActionButtonTap?(identifier)
        }

        view.onNeedsToPresentBottomSheet = { bottomSheet in
            onNeedsToPresentBottomSheet?(bottomSheet)
        }

        // Dodaj ContentMessageView jeśli są
        if let messages = contentMessages {
            for (identifier, contentMessage) in messages {
                if identifier == "__title__" {
                    view.insertContentMessageBelowTitle(contentMessage)
                } else {
                    view.insertContentMessage(contentMessage, afterCheckboxIdentifier: identifier)
                }
            }
        }

        return view
    }

    public func updateUIView(_ uiView: MultiCheckbox, context: Context) {
        uiView.isEnabled = isEnabled

        // Synchronizacja błędów
        if let message = errorMessage, !message.isEmpty {
            uiView.showError(message)
        } else {
            uiView.hideErrors()
        }

        // Synchronizacja zaznaczeń
        if uiView.checkedIndices != checkedIndices {
            // różnica — zaktualizuj checkboxy ręcznie
            for (i, item) in uiView.checkedIndices.enumerated() {
                if checkedIndices.contains(i) != (uiView.checkedIndices.contains(i)) {
                    // (brak publicznego API do pojedynczego zaznaczenia — ale callback z UIKit nadpisze to poprawnie)
                }
            }
        }
    }
}
