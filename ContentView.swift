static let liveValue = WatchlistFeatureClient(
    fetchData: {
        @Dependency(\.watchlistConfigurationRepository) var repository

        let configuration = try await repository.fetchWatchlistConfiguration()

        // 1️⃣ Sekcje posortowane po defaultOrder
        let sections = configuration.watchlistItems
            .filter { $0.parentId == nil }
            .sorted { $0.defaultOrder < $1.defaultOrder }

        // 2️⃣ Itemy posortowane po defaultOrder
        let items = configuration.watchlistItems
            .filter { $0.parentId != nil }
            .sorted { $0.defaultOrder < $1.defaultOrder }

        let selectedIds = Set(configuration.selectedWatchlistItemsIds)

        // 3️⃣ Mapowanie zachowujące kolejność
        func mapItems(
            _ items: [WatchlistConfigurationItemEntity]
        ) -> [WatchlistFeature.WatchlistItem] {
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
            groupInCategories: configuration.groupInCategories,
            allItems: mapItems(items),
            visibleItems: mapItems(
                items.filter { selectedIds.contains($0.id) }
            )
        )
    },
    updateData: { ids in
        @Dependency(\.watchlistConfigurationRepository) var repository
        try await repository.updateWatchlistConfiguration(
            visibleWatchlistIds: ids
        )
    }
)
