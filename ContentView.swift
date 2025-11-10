import SwiftUI

/// Thread-safe cache actor for storing font width measurements with LRU eviction
@globalActor
actor FontWidthCacheActor {
    static let shared = FontWidthCacheActor()
    
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
        guard var entry = cache[key] else {
            return nil
        }
        
        // Update access statistics
        entry.accessed()
        cache[key] = entry
        
        return entry.value
    }
    
    func set(key: String, value: CGFloat) {
        // If we're at capacity and this is a new key, evict least recently used entries
        if cache.count >= maxSize && cache[key] == nil {
            evictLeastRecentlyUsed()
        }
        
        if var existing = cache[key] {
            // Update existing entry
            existing.accessed()
            cache[key] = CacheEntry(value: value)
        } else {
            // Add new entry
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
    
    /// Evicts the least recently used entries (about 10% of cache)
    private func evictLeastRecentlyUsed() {
        let entriesToEvict = max(1, maxSize / 10)
        
        // Sort by last accessed time (oldest first) and access count (least used first)
        let sortedEntries = cache.sorted { (lhs, rhs) in
            let (_, entryA) = lhs
            let (_, entryB) = rhs
            
            // Primary sort: by access count (ascending - least used first)
            if entryA.accessCount != entryB.accessCount {
                return entryA.accessCount < entryB.accessCount
            }
            
            // Secondary sort: by last accessed time (ascending - oldest first)
            return entryA.lastAccessed < entryB.lastAccessed
        }
        
        // Remove the least recently/frequently used entries
        let keysToRemove = Array(sortedEntries.prefix(entriesToEvict).map { $0.key })
        keysToRemove.forEach { cache.removeValue(forKey: $0) }
    }
    
    /// Returns cache statistics for debugging/monitoring
    func getCacheStats() -> (count: Int, maxSize: Int, entries: [(key: String, accessCount: Int, lastAccessed: Date)]) {
        let entries = cache.map { (key, entry) in
            (key: key, accessCount: entry.accessCount, lastAccessed: entry.lastAccessed)
        }.sorted { $0.accessCount > $1.accessCount } // Most accessed first
        
        return (count: cache.count, maxSize: maxSize, entries: entries)
    }
}

/// A helper to efficiently measure the width needed for columns based on string content and SwiftUI font.
public struct ColumnWidthCalculator {

    /// Computes the maximum width needed for the given values, using the specified font, up to an optional maxWidth.
    /// - Parameters:
    ///   - values: The strings to measure.
    ///   - font: The SwiftUI Font for measurement.
    ///   - maxWidth: Optionally clamp the result to a maximum width.
    /// - Returns: The maximum width in points needed to fit the widest string.
    public static func maxWidth(for values: [String], font: Font, maxWidth: CGFloat? = nil) async -> CGFloat {
        guard !values.isEmpty else { return 0 }
        
        // Calculate all widths sequentially since cache access is serialized anyway
        var widths: [CGFloat] = []
        for value in values {
            let width = await width(for: value, font: font)
            widths.append(width)
        }
        
        let maxVal = widths.max() ?? 0
        if let maxWidth, maxVal > maxWidth {
            return maxWidth
        }
        return maxVal
    }

    /// Computes the width for a single string and font, using cache.
    public static func width(for string: String, font: Font) async -> CGFloat {
        let key = "\(string)-\(fontCacheKey(for: font))"
        
        return await FontWidthCacheActor.shared.getOrCompute(key: key) {
            Self.measureWidth(string: string, font: font)
        }
    }
    
    /// The core measurement, using NSAttributedString for cross-platform accuracy.
    private static func measureWidth(string: String, font: Font) -> CGFloat {
        var attributedString = AttributedString(string)
        attributedString.font = font

        // Use NSAttributedString conversion for measurement
        let nsAttributedString = NSAttributedString(attributedString)
        let size = nsAttributedString.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size

        return ceil(size.width)
    }    
}
 
