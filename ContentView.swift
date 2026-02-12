import ComposableArchitecture
import SwiftUI

struct WatchlistFilterAddView: View {
    @Bindable var store: StoreOf<WatchlistFeature>

    var body: some View {
        VStack(spacing: 0) {
            if store.isLoading {
                loader
            } else {
                tableView
                searchBar
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    store.send(.dismiss)
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.title3)
                        .foregroundStyle(Color.xmarkImageGray)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(Color.xmarkBackgroundGray)
            }
            ToolbarItem(placement: .principal) {
                Text("Add Watchlist")
                    .font(.title3.bold())
                    .foregroundStyle(Color.mainNavigation)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbarBackground(Color.whiteBackground, for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        .onAppear {
            store.send(.onAppear)
        }
        .tint(Color.accentColor)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.whiteBackground).ignoresSafeArea())
        .alert($store.scope(state: \.error?.alert, action: \.error.alert))
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(Color.text)

            TextField(
                "Search Watchlist",
                text: $store.searchText.sending(\.searchTextChanged)
            )
            .font(.body)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            if !store.searchText.isEmpty {
                Button {
                    store.send(.clearSearch)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.text)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.grayBackground)
        )
        .padding(.horizontal, 26)
    }

    private var tableView: some View {
        List {
            ForEach(store.sectionedAvailableItems, id: \.section) { sectionGroup in
                let sectionStyle = getSectionHeaderStyle(section: sectionGroup)
                Section(
                    header: SectionHeaderView(
                        sectionName: sectionGroup.section,
                        style: sectionStyle
                    ) {
                        handleSectionTap(for: sectionStyle, section: sectionGroup)
                    }
                ) {
                    ForEach(sectionGroup.items, id: \.id) { item in
                        let inArray = store.selectedItems.contains(where: {
                            $0.id == item.id
                        })
                        cellView(item: item, isAdded: inArray)
                            .listRowSeparator(
                                item == sectionGroup.items.last ? .hidden : .visible
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color(.whiteBackground))
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .listSectionSpacing(ListSectionSpacing.custom(0))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listStyle(.plain)
        .overlay {
            if store.availableItems.isEmpty {
                WatchlistEmptyView.emptySearch
            }
        }
    }

    @ViewBuilder
    private func cellView(item: WatchlistFeature.WatchlistItem, isAdded: Bool) -> some View {
        HStack {
            if isAdded {
                CheckmarkView.createCheckedkBlueFilled {
                    store.send(.removeItem(item))
                }
                .padding(.horizontal, 16)
            } else {
                CheckmarkView.createUnchecked {
                    store.send(.addItem(item))
                }
                .padding(.horizontal, 16)
            }

            Text(item.name)
                .font(.body)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var loader: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
            .frame(height: 44)
    }
}

private extension WatchlistFilterAddView {
    func getSectionHeaderStyle(section: WatchlistFeature.SectionGroup) -> SectionHeaderView.Style {
        let intersection = Set(section.items.map(\.id))
            .intersection(store.selectedItems.map(\.id))

        switch intersection.count {
        case 0:
            return .empty
        case section.items.count:
            return .fullySelectedItems
        default:
            return .partialySelectedItems
        }
    }

    func handleSectionTap(for style: SectionHeaderView.Style, section: WatchlistFeature.SectionGroup) {
        switch style {
        case .empty:
            store.send(.addItems(section.items))
        case .fullySelectedItems, .partialySelectedItems:
            store.send(.removeItems(section.items))
        case .noCheckmark:
            break
        }
    }
}

#Preview {
    NavigationView {
        WatchlistFilterAddView(
            store: Store(initialState: WatchlistFeature.State()) {
                WatchlistFeature()
            })
    }
}
