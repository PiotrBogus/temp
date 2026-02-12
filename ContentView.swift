private var tableView: some View {
    ScrollView {
        LazyVStack(
            spacing: 0,
            pinnedViews: [.sectionHeaders]
        ) {
            ForEach(store.sectionedAvailableItems, id: \.section) { sectionGroup in
                let sectionStyle = getSectionHeaderStyle(section: sectionGroup)

                Section {
                    ForEach(sectionGroup.items, id: \.id) { item in
                        let inArray = store.selectedItems.contains { $0.id == item.id }

                        cellView(item: item, isAdded: inArray)
                            .background(Color.whiteBackground)
                            .overlay(
                                Divider(),
                                alignment: .bottom
                            )
                    }
                } header: {
                    SectionHeaderView(
                        sectionName: sectionGroup.section,
                        style: sectionStyle
                    ) {
                        handleSectionTap(
                            for: sectionStyle,
                            section: sectionGroup
                        )
                    }
                    .background(Color.whiteBackground)
                }
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


ForEach(Array(sectionGroup.items.enumerated()), id: \.element.id) { index, item in
    cellView(item: item, isAdded: inArray)
    
    if index != sectionGroup.items.count - 1 {
        Divider()
    }
}
