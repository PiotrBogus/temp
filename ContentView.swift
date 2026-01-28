import ComposableArchitecture
import GenieCommonDomain
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
                            .onDelete { offsets in
                                store.send(
                                    .deleteItems(offsets, section: sectionGroup.section))
                            }
                            .onMove { source, destination in
                                store.send(
                                    .moveItems(
                                        source: source, destination: destination,
                                        section: sectionGroup.section))
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                }
                .listStyle(.plain)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .environment(\.editMode, $store.editMode.sending(\.setEditMode))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Watchlist")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.delegate(.pushToAdd))
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .tint(Color.accentColor)
            .overlay {
                if store.selectedItems.isEmpty {
                    EmptyItemsView(hasSearchText: false)
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(item: WatchlistConfigurationItemEntity) -> some View {
        HStack {
            Text(item.title)
                .font(.body)
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0))
            Spacer()
        }
        .padding(.vertical, 2)
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



import ComposableArchitecture
import GenieCommonDomain
import SwiftUI

@Reducer
public struct WatchlistFeature {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        public var allItems: [WatchlistConfigurationItemEntity] = []
        public var selectedWatchlistItemsIds: [Int] = []
        public var searchText: String = ""
        public var editMode: EditMode = .active

        public init() {}

        public var availableItems: [WatchlistConfigurationItemEntity] {
            let filtered = allItems.filter { !selectedWatchlistItemsIds.contains($0.id) }

            if searchText.isEmpty {
                return filtered
            } else {
                return filtered.filter {
                    $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.section.localizedCaseInsensitiveContains(searchText)
                }
            }
        }

        public var sectionedSelectedItems: [SectionGroup] {
            sectioned(selectedItems)
        }

        public var sectionedAllItems: [SectionGroup] {
            sectioned(allItems)
        }
    }

    public enum Action: Sendable, Equatable {
        case onAppear
        case dataLoaded(WatchlistConfigurationEntity)
        case addItem(WatchlistConfigurationItemEntity)
        case clearSearch
        case deleteItems(IndexSet, section: String)
        case delegate(Delegate)
        case moveItems(source: IndexSet, destination: Int, section: String)
        case removeItem(WatchlistConfigurationItemEntity)
        case searchTextChanged(String)
        case setEditMode(EditMode)

        public enum Delegate: Sendable {
            case pushToAdd
        }
    }

    @Dependency(\.watchlistFeatureClient) var client

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return fetchData()

            case .dataLoaded(let configuration):
                state.allItems = configuration.watchlistItems
                state.selectedWatchlistItemsIds = configuration.selectedWatchlistItemsIds
                return .none

            case let .addItem(item):
                if !state.selectedItems.contains(where: { $0.id == item.id }) {
                    state.selectedItems.append(item)
                }
                return .none

            case let .removeItem(item):
                state.selectedItems.removeAll(where: { $0.id == item.id })
                return .none

            case let .deleteItems(offsets, section):
                let itemsToDelete = state.selectedItems
                    .enumerated()
                    .compactMap { index, item in
                        item.section == section ? index : nil
                    }

                let indicesToDelete = itemsToDelete.enumerated().compactMap {
                    localIndex, globalIndex in
                    offsets.contains(localIndex) ? globalIndex : nil
                }

                state.selectedItems.remove(atOffsets: IndexSet(indicesToDelete))
                return .none

            case let .moveItems(source, destination, section):
                let sectionItems = state.selectedItems.filter { $0.section == section }
                guard !sectionItems.isEmpty else { return .none }

                guard
                    let globalStartIndex = state.selectedItems.firstIndex(where: {
                        $0.section == section
                    })
                else {
                    return .none
                }

                let globalSourceIndices = IndexSet(source.map { globalStartIndex + $0 })
                let globalDestination = globalStartIndex + destination

                state.selectedItems.move(
                    fromOffsets: globalSourceIndices, toOffset: globalDestination)
                return .none

            case let .searchTextChanged(text):
                state.searchText = text
                return .none

            case .clearSearch:
                state.searchText = ""
                return .none

            case let .setEditMode(editMode):
                state.editMode = editMode
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

extension WatchlistFeature {
    private func fetchData() -> Effect<Action> {

        return .run { send in
            let watchlistConfiguration = try await client.fetchConfigurationData()
            await send(.dataLoaded(watchlistConfiguration))
        } catch: { error, _ in
            print(error)
        }
    }
}

// MARK: - Data Models

extension WatchlistFeature {
    public struct SectionGroup: Equatable {
        public let section: String
        public let items: [WatchlistConfigurationItemEntity]

        public init(section: String, items: [WatchlistConfigurationItemEntity]) {
            self.section = section
            self.items = items
        }
    }
}

// MARK: - Helper Functions

private func sectioned(_ items: [WatchlistConfigurationItemEntity]) -> [WatchlistFeature.SectionGroup] {
    let sections = items.filter { $0.parentId != nil }
    let itemsWithoutSections = items.filter { $0.parentId == nil }

    let sections = sections.compactMap { section in
        WatchlistFeature.SectionGroup(
            section: section.title,
            items: itemsWithoutSections.filter { section.id != $0.id }
        )
    }
    return sections
}
