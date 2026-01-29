static let liveValue = WatchlistFeatureClient(
    fetchData: {
        @Dependency(\.watchlistConfigurationRepository) var repository

        let configuration = try await repository.fetchWatchlistConfiguration()

        let sections = configuration.watchlistItems.filter { $0.parentId == nil }
        let items = configuration.watchlistItems.filter { $0.parentId != nil }

        let selectedIds = Set(configuration.selectedWatchlistItemsIds)

        func mapItems(_ items: [WatchlistConfigurationItem]) -> [WatchlistFeature.WatchlistItem] {
            items.compactMap { item in
                guard let section = sections.first(where: { $0.id == item.parentId }) else {
                    return nil
                }
                return WatchlistFeature.WatchlistItem(
                    id: item.id,
                    name: item.title,
                    section: section.title
                )
            }
        }

        return WatchlistFeature.WatchlistData(
            allItems: mapItems(items),
            visibleItems: mapItems(items.filter { selectedIds.contains($0.id) })
        )
    },
    updateData: { ids in
        @Dependency(\.watchlistConfigurationRepository) var repository
        try await repository.updateWatchlistConfiguration(visibleWatchlistIds: ids)
    }
)
