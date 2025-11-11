import SwiftUI
import UIKit

private static func measureWidth(string: String, font: Font) -> CGFloat {
    // Spróbuj zamienić SwiftUI.Font na UIFont
    let uiFont: UIFont
    switch font {
    case .largeTitle: uiFont = .preferredFont(forTextStyle: .largeTitle)
    case .title: uiFont = .preferredFont(forTextStyle: .title1)
    case .headline: uiFont = .preferredFont(forTextStyle: .headline)
    case .body: uiFont = .preferredFont(forTextStyle: .body)
    default: uiFont = .systemFont(ofSize: UIFont.systemFontSize)
    }

    let attributes: [NSAttributedString.Key: Any] = [.font: uiFont]
    let size = (string as NSString).boundingRect(
        with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                     height: CGFloat.greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attributes,
        context: nil
    ).size

    return ceil(size.width)
}
