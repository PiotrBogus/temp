private var tableView: some View {
    ScrollView {
        LazyVStack(
            spacing: 0,
            pinnedViews: [.sectionHeaders]
        ) {
            ForEach(store.sectionedAvailableItems, id: \.section) { sectionGroup in
                WatchlistSectionView(
                    sectionGroup: sectionGroup,
                    selectedItems: store.selectedItems,
                    onSectionTap: handleSectionTap,
                    onAdd: { store.send(.addItem($0)) },
                    onRemove: { store.send(.removeItem($0)) }
                )
            }
        }
    }
    .background(Color.whiteBackground)
    .overlay {
        if store.availableItems.isEmpty {
            WatchlistEmptyView.emptySearch
        }
    }
}
