import SwiftUI
import UIKit
import Foundation

public struct WidthCalculator {

    // MARK: - TEXT WIDTH (SwiftUI Font)
    public static func width(
        for string: String,
        font: Font,
        weight: Font.Weight = .regular
    ) async -> CGFloat {

        let key = "text-swiftui-\(string)-\(font.hashValue)-\(weight)"

        return await WidthCacheStorage.cache.getOrComputeAsync(forKey: key) {
            let uiWeight = FontWeightMapper.uiWeight(weight: weight)
            let uiFont = FontMapper.uiFont(font: font, uiWeight: uiWeight)
            return measureText(string: string, uiFont: uiFont)
        }
    }

    // MARK: - TEXT WIDTH (UIKit Font)
    public static func width(for string: String, uiFont: UIFont) async -> CGFloat {
        let key = "text-uikit-\(string)-\(uiFont.fontDescriptor.description)"

        return await WidthCacheStorage.cache.getOrComputeAsync(forKey: key) {
            measureText(string: string, uiFont: uiFont)
        }
    }

    // MARK: - SF SYMBOL WIDTH (SwiftUI Font)
    public static func symbolWidth(
        for systemName: String,
        font: Font,
        weight: Font.Weight = .regular
    ) async -> CGFloat {

        let key = "symbol-swiftui-\(systemName)-\(font.hashValue)-\(weight)"

        return await WidthCacheStorage.cache.getOrComputeAsync(forKey: key) {
            let uiWeight = FontWeightMapper.uiWeight(weight: weight)
            let uiFont = FontMapper.uiFont(font: font, uiWeight: uiWeight)
            return measureSymbol(systemName: systemName, uiFont: uiFont)
        }
    }

    // MARK: - SF SYMBOL WIDTH (UIKit Font)
    public static func symbolWidth(for systemName: String, uiFont: UIFont) async -> CGFloat {
        let key = "symbol-uikit-\(systemName)-\(uiFont.fontDescriptor.description)"

        return await WidthCacheStorage.cache.getOrComputeAsync(forKey: key) {
            measureSymbol(systemName: systemName, uiFont: uiFont)
        }
    }

    // MARK: - MEASUREMENT
    private static func measureText(string: String, uiFont: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: uiFont]
        let size = (string as NSString).boundingRect(
            with: CGSize(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).size
        return ceil(size.width)
    }

    private static func measureSymbol(systemName: String, uiFont: UIFont) -> CGFloat {
        guard let baseImage = UIImage(systemName: systemName) else { return 0 }
        let config = UIImage.SymbolConfiguration(font: uiFont)
        let img = baseImage.applyingSymbolConfiguration(config) ?? baseImage
        return ceil(img.size.width)
    }
}


enum WidthCacheStorage {
    static let cache = WidthCache(maxSize: 2000)
}



public typealias WidthCache = LRUCache<String, CGFloat>
