import SwiftUI

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
            existing.value == value // optional consistency check
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
    public static func maxWidth(for values: [String], font: Font, maxWidth: CGFloat? = nil) async -> CGFloat {
        guard !values.isEmpty else { return 0 }
        
        var widths: [CGFloat] = []
        for value in values {
            let width = await width(for: value, font: font)
            widths.append(width)
        }
        
        let maxVal = widths.max() ?? 0
        return min(maxWidth ?? maxVal, maxVal)
    }

    public static func width(for string: String, font: Font) async -> CGFloat {
        let key = "\(string)-\(fontCacheKey(for: font))"
        return await FontWidthCacheActor.shared.getOrCompute(key: key) {
            Self.measureWidth(string: string, font: font)
        }
    }
    
    private static func measureWidth(string: String, font: Font) -> CGFloat {
        var attributed = AttributedString(string)
        attributed.font = font
        
        let ns = NSAttributedString(attributed)
        let size = ns.boundingRect(
            with: CGSize(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        return ceil(size.width)
    }
    
    private static func fontCacheKey(for font: Font) -> String {
        let desc = font.description
        return desc.replacingOccurrences(of: " ", with: "_")
    }
}
