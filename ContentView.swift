import SwiftUI
import UIKit
import Foundation

// MARK: - Global Actor Definition

@globalActor
struct FontWidthCacheActor {
    static let shared = FontWidthCacheActorImplementation()
}

// MARK: - Implementation

actor FontWidthCacheActorImplementation {
    private struct CacheEntry {
        let value: CGFloat
        var accessCount: Int
        var lastAccessed: Date

        init(value: CGFloat) {
            self.value = value
            self.accessCount = 1
            self.lastAccessed = Date()
        }

        mutating func accessed() {
            accessCount += 1
            lastAccessed = Date()
        }
    }

    private var cache: [String: CacheEntry] = [:]
    private let maxSize = 1000 // Prevent unlimited growth

    func get(key: String) -> CGFloat? {
        guard var entry = cache[key] else { return nil }
        entry.accessed()
        cache[key] = entry
        return entry.value
    }

    func set(key: String, value: CGFloat) {
        if cache.count >= maxSize && cache[key] == nil {
            evictLeastRecentlyUsed()
        }

        if var existing = cache[key] {
            existing.value == value
            existing.accessed()
            cache[key] = existing
        } else {
            cache[key] = CacheEntry(value: value)
        }
    }

    func getOrCompute(key: String, compute: () -> CGFloat) -> CGFloat {
        if let cached = get(key: key) {
            return cached
        }

        let computed = compute()
        set(key: key, value: computed)
        return computed
    }

    private func evictLeastRecentlyUsed() {
        let entriesToEvict = max(1, maxSize / 10)
        let sortedEntries = cache.sorted { a, b in
            if a.value.accessCount != b.value.accessCount {
                return a.value.accessCount < b.value.accessCount
            }
            return a.value.lastAccessed < b.value.lastAccessed
        }
        let keysToRemove = sortedEntries.prefix(entriesToEvict).map { $0.key }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
    }

    func getCacheStats() -> (count: Int, maxSize: Int, entries: [(key: String, accessCount: Int, lastAccessed: Date)]) {
        let entries = cache.map { (key, entry) in
            (key: key, accessCount: entry.accessCount, lastAccessed: entry.lastAccessed)
        }.sorted { $0.accessCount > $1.accessCount }

        return (count: cache.count, maxSize: maxSize, entries: entries)
    }
}

// MARK: - Column Width Calculator

public struct ColumnWidthCalculator {
    public static func maxWidth(for values: [String], font: Font, weight: Font.Weight = .regular, maxWidth: CGFloat? = nil) async -> CGFloat {
        guard !values.isEmpty else { return 0 }

        var widths: [CGFloat] = []
        for value in values {
            let width = await width(for: value, font: font, weight: weight)
            widths.append(width)
        }

        let maxVal = widths.max() ?? 0
        return min(maxWidth ?? maxVal, maxVal)
    }

    public static func width(for string: String, font: Font, weight: Font.Weight = .regular) async -> CGFloat {
        let key = "\(string)-\(fontCacheKey(for: font))"
        return await FontWidthCacheActor.shared.getOrCompute(key: key) {
            Self.measureWidth(string: string, font: font, weight: weight)
        }
    }

    private static func measureWidth(string: String, font: Font, weight: Font.Weight) -> CGFloat {
        let uiWeight: UIFont.Weight
        switch weight {
        case .ultraLight: uiWeight = .ultraLight
        case .thin: uiWeight = .thin
        case .light: uiWeight = .light
        case .regular: uiWeight = .regular
        case .medium: uiWeight = .medium
        case .semibold: uiWeight = .semibold
        case .bold: uiWeight = .bold
        case .heavy: uiWeight = .heavy
        default: uiWeight = .regular
        }

        let uiFont: UIFont
        switch font {
        case .largeTitle: uiFont = .preferredFont(forTextStyle: .largeTitle, weight: uiWeight)
        case .title: uiFont = .preferredFont(forTextStyle: .title1, weight: uiWeight)
        case .headline: uiFont = .preferredFont(forTextStyle: .headline, weight: uiWeight)
        case .body: uiFont = .preferredFont(forTextStyle: .body, weight: uiWeight)
        case .footnote: uiFont = .preferredFont(forTextStyle: .footnote, weight: uiWeight)
        case .caption: uiFont = .preferredFont(forTextStyle: .caption1, weight: uiWeight)
        case .caption2: uiFont = .preferredFont(forTextStyle: .caption2, weight: uiWeight)
        default: uiFont = .systemFont(ofSize: UIFont.systemFontSize, weight: uiWeight)
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

    private static func fontCacheKey(for font: Font) -> String {
        let desc = font.hashValue.description
        return desc.replacingOccurrences(of: " ", with: "_")
    }
}

extension UIFont {
    static func preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
            .addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: weight
                ]
            ])
        return UIFont(descriptor: descriptor, size: 0)
    }
}
