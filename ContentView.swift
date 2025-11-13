import UIKit
import SwiftUI

/// Prosty, szybki kalkulator szerokości tekstu (jedna linia).
public enum TextWidthCalculator {
    private static let cache = NSCache<NSString, NSNumber>()

    /// Mierzy szerokość podanego tekstu (jedna linia) przy użyciu UIFont i opcjonalnych atrybutów.
    /// - Parameters:
    ///   - text: tekst do zmierzenia
    ///   - font: UIFont użyty do renderowania
    ///   - attributes: dodatkowe atrybuty NSAttributedString.Key (np. kern), opcjonalne
    ///   - useCache: czy użyć prostego cache (default true)
    /// - Returns: szerokość w punktach (CGFloat), zaokrąglona w górę (ceil)
    public static func width(
        for text: String,
        font: UIFont,
        attributes: [NSAttributedString.Key: Any]? = nil,
        useCache: Bool = true
    ) -> CGFloat {
        guard !text.isEmpty else { return 0 }

        // Key dla cache — łączy tekst + font description + opcjonalne atrybuty ważne do pomiaru
        if useCache {
            let attrDesc = attributes?.map { "\($0.key.rawValue)=\($0.value)" }.joined(separator: "|") ?? ""
            let cacheKey = "\(text)|font:\(font.fontName)-\(font.pointSize)|attrs:\(attrDesc)" as NSString
            if let cached = cache.object(forKey: cacheKey) {
                return CGFloat(truncating: cached)
            }

            let computed = computeWidth(text: text, font: font, attributes: attributes)
            cache.setObject(NSNumber(value: Double(computed)), forKey: cacheKey)
            return computed
        } else {
            return computeWidth(text: text, font: font, attributes: attributes)
        }
    }

    /// Mierzy szerokość dla NSAttributedString (jedna linia).
    public static func width(for attributed: NSAttributedString, useCache: Bool = false) -> CGFloat {
        guard attributed.length > 0 else { return 0 }

        if useCache {
            let cacheKey = "attr:\(attributed.string)|\(attributed.hash)" as NSString
            if let cached = cache.object(forKey: cacheKey) {
                return CGFloat(truncating: cached)
            }
            let size = attributed.size()
            let w = ceil(size.width)
            cache.setObject(NSNumber(value: Double(w)), forKey: cacheKey)
            return w
        } else {
            return ceil(attributed.size().width)
        }
    }

    /// Wersja wygodna dla SwiftUI Font — mapujemy do UIFont (ograniczona konwersja).
    /// Jeśli potrzebujesz precyzyjnej konwersji, podaj bezpośrednio UIFont.
    public static func width(
        for text: String,
        font: Font,
        attributes: [NSAttributedString.Key: Any]? = nil,
        useCache: Bool = true
    ) -> CGFloat {
        let uiFont = uiFont(from: font)
        return width(for: text, font: uiFont, attributes: attributes, useCache: useCache)
    }

    // MARK: - Helpers

    private static func computeWidth(text: String, font: UIFont, attributes: [NSAttributedString.Key: Any]?) -> CGFloat {
        var attrs = attributes ?? [:]
        attrs[.font] = font
        // NSString API dla jednej linii — szybkie i dokładne
        let ns = text as NSString
        let size = ns.size(withAttributes: attrs)
        return ceil(size.width)
    }

    /// Prosta (przybliżona) konwersja SwiftUI Font -> UIFont
    private static func uiFont(from font: Font) -> UIFont {
        // Najczęstsze mappingi; rozszerz w razie potrzeby
        switch font {
        case .largeTitle:
            return UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title:
            return UIFont.preferredFont(forTextStyle: .title1)
        case .title2:
            return UIFont.preferredFont(forTextStyle: .title2)
        case .title3:
            return UIFont.preferredFont(forTextStyle: .title3)
        case .headline:
            return UIFont.preferredFont(forTextStyle: .headline)
        case .subheadline:
            return UIFont.preferredFont(forTextStyle: .subheadline)
        case .callout:
            return UIFont.preferredFont(forTextStyle: .callout)
        case .caption:
            return UIFont.preferredFont(forTextStyle: .caption1)
        case .caption2:
            return UIFont.preferredFont(forTextStyle: .caption2)
        case .footnote:
            return UIFont.preferredFont(forTextStyle: .footnote)
        default:
            // fallback: body
            return UIFont.preferredFont(forTextStyle: .body)
        }
    }
}
