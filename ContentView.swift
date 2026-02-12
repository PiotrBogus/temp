private struct WatchlistSectionView: View {
    let sectionGroup: WatchlistFeature.SectionGroup
    let selectedItems: [WatchlistFeature.WatchlistItem]
    let onSectionTap: (SectionHeaderView.Style, WatchlistFeature.SectionGroup) -> Void
    let onAdd: (WatchlistFeature.WatchlistItem) -> Void
    let onRemove: (WatchlistFeature.WatchlistItem) -> Void

    var body: some View {
        let style = sectionStyle

        Section {
            ForEach(sectionGroup.items, id: \.id) { item in
                let isAdded = selectedItems.contains { $0.id == item.id }

                cell(item: item, isAdded: isAdded)
            }
        } header: {
            SectionHeaderView(
                sectionName: sectionGroup.section,
                style: style
            ) {
                onSectionTap(style, sectionGroup)
            }
            .background(Color.whiteBackground)
        }
    }

    private func cell(
        item: WatchlistFeature.WatchlistItem,
        isAdded: Bool
    ) -> some View {
        HStack {
            if isAdded {
                CheckmarkView.createCheckedkBlueFilled {
                    onRemove(item)
                }
                .padding(.horizontal, 16)
            } else {
                CheckmarkView.createUnchecked {
                    onAdd(item)
                }
                .padding(.horizontal, 16)
            }

            Text(item.name)
                .font(.body)
            Spacer()
        }
        .padding(.vertical, 4)
        .background(Color.whiteBackground)
        .overlay(Divider(), alignment: .bottom)
    }

    private var sectionStyle: SectionHeaderView.Style {
        let intersection = Set(sectionGroup.items.map(\.id))
            .intersection(selectedItems.map(\.id))

        switch intersection.count {
        case 0:
            .empty
        case sectionGroup.items.count:
            .fullySelectedItems
        default:
            .partialySelectedItems
        }
    }
}
