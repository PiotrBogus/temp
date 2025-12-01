//
//  LRUCache.swift
//  GenieCommon
//
//  Created by Jan Kase on 31.10.2025.
//

import Dependencies
import Foundation

/// A thread-safe, generic Least Recently Used (LRU) cache implementation using Swift actors.
///
/// `LRUCache` provides automatic memory management through intelligent eviction policies,
/// combining both recency and frequency of access to determine which items to remove when
/// the cache reaches its capacity limit.
///
/// ## Features
///
/// - **Thread-safe**: Uses Swift actors to ensure safe concurrent access
/// - **Generic**: Supports any `Hashable & Sendable` key and `Sendable` value types
/// - **Intelligent Eviction**: Considers both access frequency and recency
/// - **Statistics**: Provides detailed cache performance metrics
/// - **Testable**: Uses TCA Dependencies for controllable date/time in tests
/// - **Async Support**: Includes async variants of compute methods
///
/// ## Usage Examples
///
/// ### Basic Operations
/// ```swift
/// let cache = LRUCache<String, User>(maxSize: 100)
///
/// // Store a value
/// await cache.set(user, forKey: "user123")
///
/// // Retrieve a value
/// if let cachedUser = await cache.get(forKey: "user123") {
///     print("Found cached user: \(cachedUser.name)")
/// }
/// ```
///
/// ### Compute-on-Miss Pattern
/// ```swift
/// let userCache = LRUCache<String, User>(maxSize: 50)
///
/// // Synchronous compute
/// let user = await userCache.getOrCompute(forKey: userId) {
///     return loadUserFromDisk(userId)
/// }
///
/// // Async compute
/// let user = await userCache.getOrCompute(forKey: userId) {
///     return await fetchUserFromAPI(userId)
/// }
/// ```
///
/// ### Cache Statistics
/// ```swift
/// let stats = await cache.getCacheStats()
/// print("Cache utilization: \(stats.count)/\(stats.maxSize)")
/// print("Most accessed item: \(stats.entries.first?.key ?? "none")")
/// ```
///
/// ## Eviction Policy
///
/// When the cache reaches its `maxSize`, approximately 10% of the least valuable entries
/// are evicted. The eviction algorithm considers:
/// 1. **Access frequency**: Items accessed fewer times are evicted first
/// 2. **Recency**: Among items with equal access counts, older items are evicted first
///
/// This hybrid approach provides better performance than pure LRU for many real-world
/// access patterns, especially those with "hot" data that's accessed frequently.
///
/// ## Thread Safety
///
/// All operations are thread-safe through the actor model. Multiple concurrent calls
/// to `get`, `set`, and other methods are automatically serialized by the actor runtime.
///
/// - Parameters:
///   - Key: The type used for cache keys. Must conform to `Hashable & Sendable`
///   - Value: The type used for cached values. Must conform to `Sendable`
public actor LRUCache<Key: Hashable & Sendable, Value: Sendable> {
    /// Internal storage structure for cached items.
    ///
    /// Tracks both the cached value and metadata used for eviction decisions,
    /// including access frequency and the timestamp of last access.
    private struct CacheEntry: Sendable {
        /// The cached value
        var value: Value
        /// Number of times this entry has been accessed
        var accessCount: Int
        /// Timestamp of the most recent access
        var lastAccessed: Date

        /// Creates a new cache entry with the given value.
        ///
        /// The entry is initialized with an access count of 1 and the current timestamp.
        ///
        /// - Parameter value: The value to cache
        init(value: Value) {
            @Dependency(\.date.now) var now
            self.value = value
            self.accessCount = 1
            self.lastAccessed = now
        }

        /// Updates the entry's access metadata to reflect a new access.
        ///
        /// Increments the access count and updates the last accessed timestamp
        /// to the current time.
        mutating func accessed() {
            @Dependency(\.date.now) var now
            accessCount += 1
            lastAccessed = now
        }
    }

    /// The underlying storage for cached key-value pairs
    private var cache: [Key: CacheEntry] = [:]
    /// Maximum number of items the cache can hold before triggering eviction
    private let maxSize: Int
    /// Tracks ongoing async computations to prevent duplicate work
    private var computingTasks: [Key: Task<Value, Never>] = [:]

    /// Creates a new LRU cache with the specified maximum size.
    ///
    /// - Parameter maxSize: The maximum number of items to store. Must be at least 1.
    ///   Defaults to 1000. Values less than 1 are automatically adjusted to 1.
    ///
    /// ## Example
    /// ```swift
    /// let smallCache = LRUCache<String, Data>(maxSize: 50)
    /// let defaultCache = LRUCache<String, Data>() // maxSize = 1000
    /// ```
    public init(maxSize: Int = 1000) {
        self.maxSize = max(1, maxSize)
    }

    /// Retrieves a value from the cache for the given key.
    ///
    /// If the key exists in the cache, this method updates the entry's access metadata
    /// (incrementing access count and updating last accessed time) and returns the
    /// associated value. If the key doesn't exist, returns `nil`.
    ///
    /// - Parameter key: The key to look up in the cache
    /// - Returns: The cached value if found, `nil` otherwise
    ///
    /// ## Example
    /// ```swift
    /// if let user = await cache.get(forKey: "user123") {
    ///     print("Cache hit: \(user.name)")
    /// } else {
    ///     print("Cache miss for user123")
    /// }
    /// ```
    public func get(forKey key: Key) -> Value? {
        guard var entry = cache[key] else {
            return nil
        }
        entry.accessed()
        cache[key] = entry
        return entry.value
    }

    /// Stores a value in the cache for the given key.
    ///
    /// If the cache is at capacity and the key doesn't already exist, this method
    /// triggers eviction of approximately 10% of the least valuable entries before
    /// storing the new value. If the key already exists, the old value is replaced
    /// and the entry's access metadata is updated.
    ///
    /// - Parameters:
    ///   - value: The value to store in the cache
    ///   - key: The key to associate with the value
    ///
    /// ## Example
    /// ```swift
    /// await cache.set(userData, forKey: "user123")
    /// await cache.set(updatedData, forKey: "user123") // Updates existing entry
    /// ```
    ///
    /// ## Performance Notes
    /// - Storing a new key when at capacity: O(n log n) due to eviction sorting
    /// - Updating an existing key: O(1)
    /// - Storing a new key when under capacity: O(1)
    public func set(_ value: Value, forKey key: Key) {
        if cache.count >= maxSize && !cache.contains(where: { cacheKey, _ in cacheKey == key}) {
            evictLeastRecentlyUsed()
        }

        if var existing = cache[key] {
            existing.accessed()
            existing.value = value
            cache[key] = existing
        } else {
            cache[key] = CacheEntry(value: value)
        }
    }

    /// Retrieves a cached value or computes and caches it if not present (synchronous version).
    ///
    /// This method implements the common "get-or-compute" pattern. If the key exists in
    /// the cache, it returns the cached value (updating access metadata). If not, it
    /// calls the provided compute closure to generate the value, stores it in the cache,
    /// and returns it.
    ///
    /// - Parameters:
    ///   - key: The key to look up or associate with the computed value
    ///   - compute: A closure that computes the value if not found in cache
    /// - Returns: The cached value if found, or the newly computed and cached value
    ///
    /// ## Example
    /// ```swift
    /// let expensiveResult = await cache.getOrCompute(forKey: "calculation") {
    ///     return performExpensiveCalculation()
    /// }
    /// ```
    ///
    /// ## Performance Notes
    /// The compute closure is only called if the key is not in the cache.
    /// Subsequent calls with the same key will return the cached result without
    /// calling the compute closure again.
    public func getOrCompute(forKey key: Key, compute: () -> Value) -> Value {
        if let cached = get(forKey: key) {
            return cached
        }
        let computed = compute()
        set(computed, forKey: key)
        return computed
    }

    /// Retrieves a cached value or computes and caches it if not present (asynchronous version).
    ///
    /// This is the async variant of `getOrCompute`. It's particularly useful for expensive
    /// operations like network requests or file I/O that should be cached to avoid
    /// repeated execution.
    ///
    /// **Thread Safety & Deduplication**: Multiple concurrent calls with the same key will
    /// not trigger duplicate computations. The first call will start the computation,
    /// and subsequent calls will wait for the same computation to complete, ensuring
    /// the compute closure is called only once per key.
    ///
    /// - Parameters:
    ///   - key: The key to look up or associate with the computed value
    ///   - compute: An async closure that computes the value if not found in cache
    /// - Returns: The cached value if found, or the newly computed and cached value
    ///
    /// ## Example
    /// ```swift
    /// let userData = await cache.getOrComputeAsync(forKey: userId) {
    ///     return await apiClient.fetchUser(userId)
    /// }
    /// ```
    ///
    /// ## Performance Notes
    /// The compute closure is only called if the key is not in the cache and no other
    /// computation for the same key is already in progress. This prevents expensive
    /// operations from being duplicated when multiple concurrent requests are made
    /// for the same uncached key.
    public func getOrComputeAsync(forKey key: Key, compute: @escaping () async -> Value) async -> Value {
        // First, check if we have a cached value
        if let cached = get(forKey: key) {
            return cached
        }
        
        // Check if there's already a computation in progress for this key
        if let existingTask = computingTasks[key] {
            // Wait for the existing computation to complete
            return await existingTask.value
        }
        
        // Start a new computation task
        let task = Task<Value, Never> {
            // Double-check cache after acquiring the task slot
            if let cached = get(forKey: key) {
                return cached
            }
            
            let computed = await compute()
            set(computed, forKey: key)
            return computed
        }
        
        // Store the task so other concurrent calls can wait for it
        computingTasks[key] = task
        
        // Wait for the computation to complete
        let result = await task.value
        
        // Clean up the completed task
        computingTasks.removeValue(forKey: key)
        
        return result
    }

    /// Removes approximately 10% of the least valuable entries from the cache.
    ///
    /// This method implements a hybrid LRU/LFU (Least Recently Used/Least Frequently Used)
    /// eviction policy. Entries are first sorted by access frequency (ascending), then
    /// by last access time (ascending) for ties. The least valuable entries are then
    /// removed from the cache.
    ///
    /// The eviction removes `max(1, maxSize / 10)` entries, ensuring at least one
    /// entry is removed but typically removing about 10% to avoid frequent evictions.
    ///
    /// ## Algorithm Details
    /// 1. Sort all entries by access count (low to high)
    /// 2. For entries with equal access counts, sort by last access time (old to new)
    /// 3. Remove the first ~10% of entries from this sorted list
    ///
    /// ## Time Complexity
    /// O(n log n) where n is the current cache size, due to the sorting operation.
    private func evictLeastRecentlyUsed() {
        let entriesToEvict = max(1, maxSize / 10)
        let sortedEntries = cache.sorted { (lhs, rhs) in
            let (_, entryA) = lhs
            let (_, entryB) = rhs
            if entryA.accessCount != entryB.accessCount {
                return entryA.accessCount < entryB.accessCount
            }
            return entryA.lastAccessed < entryB.lastAccessed
        }
        let keysToRemove = Array(sortedEntries.prefix(entriesToEvict).map { $0.key })
        keysToRemove.forEach { cache.removeValue(forKey: $0) }
    }

    /// Returns detailed statistics about the current cache state.
    ///
    /// This method provides comprehensive information about cache utilization and
    /// entry access patterns. It's useful for monitoring cache performance, debugging
    /// cache behavior, and optimizing cache size and eviction policies.
    ///
    /// - Returns: A tuple containing:
    ///   - `count`: Current number of items in the cache
    ///   - `maxSize`: Maximum capacity of the cache
    ///   - `entries`: Array of cache entries sorted by access count (descending),
    ///     containing key, access count, and last access timestamp
    ///
    /// ## Example
    /// ```swift
    /// let stats = await cache.getCacheStats()
    /// print("Cache utilization: \(stats.count)/\(stats.maxSize)")
    /// print("Hit rate indicator: Most accessed key has \(stats.entries.first?.accessCount ?? 0) hits")
    ///
    /// // Find entries that might be good candidates for eviction
    /// let leastUsed = stats.entries.suffix(5)
    /// print("Least used entries: \(leastUsed.map { $0.key })")
    /// ```
    ///
    /// ## Performance Notes
    /// - Time complexity: O(n log n) due to sorting by access count
    /// - This method creates a new array with all cache entries, so it should be used
    ///   judiciously in performance-critical code
    /// - Consider calling this method periodically for monitoring rather than on every operation
    public func getCacheStats() -> (count: Int, maxSize: Int, entries: [(key: Key, accessCount: Int, lastAccessed: Date)]) {
        let entries = cache.map { (key, entry) in
            (key: key, accessCount: entry.accessCount, lastAccessed: entry.lastAccessed)
        }.sorted { $0.accessCount > $1.accessCount }
        return (count: cache.count, maxSize: maxSize, entries: entries)
    }
}






import SwiftUI
import UIKit
import Foundation
// MARK: - Text Width Calculator
public struct WidthCalculator {
    // MARK: - Get text width using SwiftUI font
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
        let key = "\(string)-\(font.hashValue)"
        return await FontWidthCacheActor.shared.getOrCompute(key: key) {
            let uiWeight: UIFont.Weight = FontWeightMapper.uiWeight(weight: weight)
            let uiFont: UIFont = FontMapper.uiFont(font: font, uiWeight: uiWeight)
            return Self.measureWidth(string: string, uiFont: uiFont)
        }
    }
    // MARK: - Get text width using UIKit font
    public static func maxWidth(for values: [String], uiFont: UIFont, maxWidth: CGFloat? = nil) async -> CGFloat {
        guard !values.isEmpty else { return 0 }
        var widths: [CGFloat] = []
        for value in values {
            let width = await width(for: value, uiFont: uiFont)
            widths.append(width)
        }
        let maxVal = widths.max() ?? 0
        return min(maxWidth ?? maxVal, maxVal)
    }
    public static func width(for string: String, uiFont: UIFont) async -> CGFloat {
        let key = "\(string)-\(uiFont.description.hashValue)"
        return await FontWidthCacheActor.shared.getOrCompute(key: key) {
            Self.measureWidth(string: string, uiFont: uiFont)
        }
    }
    private static func measureWidth(string: String, uiFont: UIFont) -> CGFloat {
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
}
// MARK: - SF-Symbol Width Calculator
public extension WidthCalculator {
    // MARK: - Get symbol width using SwiftUI font
    static func symbolWidth(
        for systemName: String,
        font: Font,
        weight: Font.Weight = .regular
    ) async -> CGFloat {
        let key = "\(systemName)-\(font.hashValue)"
        return await FontWidthCacheActor.shared.getOrCompute(key: key) {
            let uiWeight = FontWeightMapper.uiWeight(weight: weight)
            let uiFont = FontMapper.uiFont(font: font, uiWeight: uiWeight)
            return Self.measureSymbolWidth(systemName: systemName, uiFont: uiFont)
        }
    }
    // MARK: - Get symbol width using UIKit font
    static func symbolWidth(
        for systemName: String,
        uiFont: UIFont,
    ) async -> CGFloat {
        let key = "\(systemName)-\(uiFont.hashValue)"
        return await FontWidthCacheActor.shared.getOrCompute(key: key) {
            Self.measureSymbolWidth(systemName: systemName, uiFont: uiFont)
        }
    }
    private static func measureSymbolWidth(
        systemName: String,
        uiFont: UIFont,
    ) -> CGFloat {
        guard let image = UIImage(systemName: systemName)?.withRenderingMode(.alwaysTemplate) else {
            return 0
        }
        let config = UIImage.SymbolConfiguration(font: uiFont)
        let scaledImage = image.applyingSymbolConfiguration(config) ?? image
        return ceil(scaledImage.size.width)
    }
}
private extension UIFont {
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
private struct FontMapper {
    static func uiFont(font: Font, uiWeight: UIFont.Weight) -> UIFont {
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
              return UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: uiWeight)
          }
      }
}
private struct FontWeightMapper {
    static func uiWeight(weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight:
            return .ultraLight
        case .thin:
            return .thin
        case .light:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        default:
            return .regular
        }
    }
}
// MARK: - Global Actor Definition
@globalActor
private struct FontWidthCacheActor {
    static let shared = FontWidthCacheActorImplementation()
}
// MARK: - Implementation
private actor FontWidthCacheActorImplementation {
    private struct CacheEntry {
        var value: CGFloat
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
    private let maxSize = 1000
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
            existing.value = value
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
