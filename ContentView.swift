import ComposableArchitecture
import SwiftUI

struct WatchlistEditView: View {
    @Bindable var store: StoreOf<WatchlistFeature>
    
    var body: some View {
        WatchlistTableView(store: store)
    }
}

struct WatchlistTableView: View {
    @Bindable var store: StoreOf<WatchlistFeature>
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            if store.isLoading {
                loader
            } else {
                if store.groupInCategories {
                    sectionedTableView
                } else {
                    tableView
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .navigationBarTitleDisplayMode(.inline)
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
                Text("Edit Watchlist")
                    .font(.title3.bold())
                    .foregroundStyle(Color.mainNavigation)
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        store.send(.onSynchronize)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundStyle(Color.xmarkImageGray)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .tint(Color.xmarkBackgroundGray)

                    Button {
                        store.send(.delegate(.pushToAdd))
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundStyle(Color.whitePrimary)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .tint(Color.mainNavigation)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .tint(Color.accentColor)
        .overlay {
            if store.selectedItems.isEmpty && !store.isLoading {
                EmptyItemsView(hasSearchText: false)
            }
        }
        .alert($store.scope(state: \.error?.alert, action: \.error.alert))
    }

    @ViewBuilder
    private var tableView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(store.selectedItems, id: \.id) { item in
                    cellView(item: item)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color(.systemBackground))
                        .listRowSeparator(
                            item == store.selectedItems.last ? .hidden : .visible)
                }
                .onMove { source, destination in
                    store.send(
                        .moveItems(
                            source: source,
                            destination: destination,
                            section: nil
                        )
                    )
                }
            }
            .listStyle(.plain)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listSectionSpacing(ListSectionSpacing.custom(0))
            .environment(\.editMode, $store.editMode.sending(\.setEditMode))
        }
    }
    
    @ViewBuilder
    private var sectionedTableView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(store.sectionedSelectedItems, id: \.section) { sectionGroup in
                    Section(
                        header: SectionHeaderView(sectionName: sectionGroup.section)
                    ) {
                        ForEach(sectionGroup.items, id: \.id) { item in
                            cellView(item: item)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color(.systemBackground))
                                .listRowSeparator(
                                    item == sectionGroup.items.last ? .hidden : .visible)
                        }
                        .onMove { source, destination in
                            store.send(
                                .moveItems(
                                    source: source,
                                    destination: destination,
                                    section: sectionGroup.section
                                )
                            )
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
            .listStyle(.plain)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listSectionSpacing(ListSectionSpacing.custom(0))
            .environment(\.editMode, $store.editMode.sending(\.setEditMode))
        }
    }

    @ViewBuilder
    private func cellView(item: WatchlistFeature.WatchlistItem) -> some View {
        HStack {
            CheckmarkView.createCheckedkBlueFilled {
                store.send(
                    .removeItem(item))
            }
            .padding(.horizontal, 16)
            
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

#Preview("Watchlist Manager") {
    NavigationView {
        WatchlistEditView(
            store: Store(initialState: WatchlistFeature.State()) {
                WatchlistFeature()
            })
    }
}
