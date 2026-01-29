import Combine
import AppCompositionData
import AppCompositionDomain
import Dependencies
import DependenciesMacros
import GenieCommonDomain
import Network

@DependencyClient
struct WatchlistFeatureClient: DependencyKey {
    var fetchData: @Sendable () async throws -> WatchlistFeature.WatchlistData

    var updateData: @Sendable ([Int]) async throws

    static let liveValue = WatchlistFeatureClient(
        fetchData: {
            @Dependency(\.watchlistConfigurationRepository) var repository

            let configuration = try await repository.fetchWatchlistConfiguration()

            let sectionsItems = configuration.watchlistItems.filter { $0.parentId == nil }
            let allItemsWithoutSections = configuration.watchlistItems.filter { $0.parentId != nil }
            let mappedAllItems = allItemsWithoutSections.compactMap { item in
                let section = sectionsItems.first(where: { $0.id == item.parentId })!
                return WatchlistFeature.WatchlistItem(
                    id: item.id,
                    name: item.title,
                    section: section.title
                )
            }

            let visibleItems = allItemsWithoutSections.filter { item in
                configuration.selectedWatchlistItemsIds.contains { $0 == item.id }
            }
            let mappedVisibleItems = visibleItems.compactMap { item in
                let section = sectionsItems.first(where: { $0.id == item.parentId })!
                return WatchlistFeature.WatchlistItem(
                    id: item.id,
                    name: item.title,
                    section: section.title
                )
            }

            return WatchlistFeature.WatchlistData(
                allItems: mappedAllItems,
                visibleItems: mappedVisibleItems
            )
        },
        updateData: {
            @Dependency(\.watchlistConfigurationRepository) var repository

            try await repository.updateWatchlistConfiguration(visibleWatchlistIds: $0)
        }
    )
}

extension DependencyValues {
    var watchlistFeatureClient: WatchlistFeatureClient {
        get { self[WatchlistFeatureClient.self] }
        set { self[WatchlistFeatureClient.self] = newValue }
    }
}
