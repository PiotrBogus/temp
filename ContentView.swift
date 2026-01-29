    private func getSectionHeaderStyle(section: WatchlistFeature.SectionGroup) -> SectionHeaderView.Style {

        if section.items.allSatisfy { item in
            store.selectedItems.contains { $0.id == item.id }
        } {
            return SectionHeaderView.fullySelectedItems
        }

        var isEmpty = true
        if store.selectedItems.forEach { item in
            if section.items.contains { $0.id == item.id } {
                isEmpty = false
                break
            }
        }

        if isEmpty {
            return SectionHeaderView.empty
        } else {
            return SectionHeaderView.partialySelectedItems
        }
    }
