private static func measureWidth(
    string: String,
    font: Font,
    weight: Font.Weight
) -> CGFloat {

    // --- Mapowanie SwiftUI Weight → UIFont.Weight ----
    let uiWeight: UIFont.Weight = {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        default:          return .regular
        }
    }()

    // --- Mapowanie SwiftUI Font → UIKit UIFont ----
    let uiFont: UIFont = {
        switch font {

        case .largeTitle:
            return .preferredFont(forTextStyle: .largeTitle, weight: uiWeight)

        case .title:
            return .preferredFont(forTextStyle: .title1, weight: uiWeight)

        case .title2:
            return .preferredFont(forTextStyle: .title2, weight: uiWeight)

        case .title3:
            return .preferredFont(forTextStyle: .title3, weight: uiWeight)

        case .headline:
            return .preferredFont(forTextStyle: .headline, weight: uiWeight)

        case .subheadline:
            return .preferredFont(forTextStyle: .subheadline, weight: uiWeight)

        case .callout:
            return .preferredFont(forTextStyle: .callout, weight: uiWeight)

        case .body:
            return .preferredFont(forTextStyle: .body, weight: uiWeight)

        case .footnote:
            return .preferredFont(forTextStyle: .footnote, weight: uiWeight)

        case .caption:
            return .preferredFont(forTextStyle: .caption1, weight: uiWeight)

        case .caption2:
            return .preferredFont(forTextStyle: .caption2, weight: uiWeight)

        default:
            // jeśli ktoś podał .system(size:), .custom(...) lub inne
            return UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: uiWeight)
        }
    }()

    // --- Pomiar szerokości tekstu ----
    let attributes: [NSAttributedString.Key: Any] = [.font: uiFont]
    let size = (string as NSString).boundingRect(
        with: CGSize(width: .greatestFiniteMagnitude,
                     height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attributes,
        context: nil
    ).size

    return ceil(size.width)
}
