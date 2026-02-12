import ComposableArchitecture
import SwiftUI

@Reducer
public struct WatchlistFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        public enum ErrorType: Equatable, Sendable {
            case fetchDataFailed
            case synchronizationFailed
            case restore
        }

        @Presents var error: ErrorFeature.State?

        public var allItems: [WatchlistItem] = []
        public var selectedItems: [WatchlistItem] = []
        public var searchText: String = ""
        public var editMode: EditMode = .active
        public var isLoading: Bool = false
        public var groupInCategories: Bool = false
        var errorType: ErrorType? = .none

        public init() {}

        public var availableItems: [WatchlistItem] {
            if searchText.isEmpty {
                return allItems
            } else {
                return allItems.filter {
                    $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.section.localizedCaseInsensitiveContains(searchText)
                }
            }
        }

        public var sectionedSelectedItems: [SectionGroup] {
            sectioned(selectedItems)
        }

        public var sectionedAvailableItems: [SectionGroup] {
            sectioned(availableItems)
        }
    }

    public enum Action: Sendable, Equatable {
        case onAppear
        case didLoadData(WatchlistData)
        case addItem(WatchlistItem)
        case addItems([WatchlistItem])
        case clearSearch
        case delegate(Delegate)
        case moveItems(source: IndexSet, destination: Int, section: String?)
        case removeItem(WatchlistItem)
        case removeItems([WatchlistItem])
        case searchTextChanged(String)
        case setEditMode(EditMode)
        case onDidUpdateData
        case onSynchronize
        case onError(ErrorFeature.State, State.ErrorType)
        case error(ErrorFeature.Action)
        case dismiss

        public enum Delegate: Sendable {
            case pushToAdd
            case editWatchListUpdated
        }
    }

    @Dependency(\.watchlistFeatureClient) private var client
    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return fetchData()

            case let .didLoadData(data):
                state.isLoading = false
                state.groupInCategories = data.groupInCategories
                state.allItems = data.allItems
                state.selectedItems = data.visibleItems
                return .none

            case let .addItem(item):
                if !state.selectedItems.contains(where: { $0.id == item.id }) {
                    state.selectedItems.append(item)
                }
                return update(visibleItems: state.selectedItems)

            case let .addItems(items):
                items.forEach { item in
                    if !state.selectedItems.contains(where: { $0.id == item.id }) {
                        state.selectedItems.append(item)
                    }
                }
                return update(visibleItems: state.selectedItems)

            case let .removeItem(item):
                state.selectedItems.removeAll(where: { $0.id == item.id })
                return update(visibleItems: state.selectedItems)

            case let .removeItems(items):
                items.forEach { item in
                    state.selectedItems.removeAll(where: { $0.id == item.id })
                }
                return update(visibleItems: state.selectedItems)

            case let .moveItems(source, destination, section):
                if let section {
                    let sectionIndices = state.selectedItems
                        .enumerated()
                        .filter { $0.element.section == section }
                        .map(\.offset)

                    let globalSource = IndexSet(
                        source.compactMap { localIndex in
                            sectionIndices[safe: localIndex]
                        }
                    )

                    let globalDestination =
                        destination < sectionIndices.count
                        ? sectionIndices[destination]
                        : (sectionIndices.last! + 1)

                    state.selectedItems.move(
                        fromOffsets: globalSource,
                        toOffset: globalDestination
                    )

                } else {
                    state.selectedItems.move(
                        fromOffsets: source,
                        toOffset: destination
                    )
                }

                return update(visibleItems: state.selectedItems)

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

            case .onDidUpdateData:
                return .send(.delegate(.editWatchListUpdated))
                
            case .onSynchronize:
                state.errorType = .restore
                state.error = ErrorFeature.State.build(
                    title: "Are you sure?",
                    message: "You are trying to restore to defaults in watchlist. Do you wish to continue?",
                    cancelButtonTitle: "No, Cancel",
                    retryButtonTitle: "Yes, Restore"
                )
                return .none

            case let .onError(error, type):
                state.isLoading = false
                state.errorType = type
                state.error = error
                return .none
                
            case .error(.delegate(.retry)):
                state.error = nil
                state.isLoading = true
                switch state.errorType {
                case .fetchDataFailed:
                    return fetchData()
                case .synchronizationFailed, .restore:
                    return synchronize()
                case .none:
                    return .none
                }

            case .error:
                return .none

            case .dismiss:
                return .run { _ in await dismiss() }

            }
        }
        .ifLet(\.error, action: \.error) { ErrorFeature() }
    }
}

extension WatchlistFeature {
    func fetchData() -> Effect<Action> {
        .run { send in
            let data = try await client.fetchData()

            await send(.didLoadData(data))
        } catch: { error, send in
            await send(.onError(.build(from: error), .fetchDataFailed))
        }
    }

    func update(visibleItems: [WatchlistItem]) -> Effect<Action> {
        .run { send in
            let ids = visibleItems.map(\.id)
            try await client.updateData(ids)

            await send(.onDidUpdateData)
        }
    }

    func synchronize() -> Effect<Action> {
        .run { send in
            try await client.updateData([])
            let data = try await client.fetchData()

            await send(.didLoadData(data))
        } catch: { error, send in
            await send(.onError(.build(from: error), .synchronizationFailed))
        }
    }
}

// MARK: - Data Models

extension WatchlistFeature {
    public struct SectionGroup: Equatable {
        public let id = UUID()
        public let section: String
        public let items: [WatchlistItem]

        public init(section: String, items: [WatchlistItem]) {
            self.section = section
            self.items = items
        }
    }

    public struct WatchlistItem: Identifiable, Equatable, Sendable {
        public let id: Int
        public let name: String
        public let section: String

        public init(id: Int, name: String, section: String) {
            self.id = id
            self.name = name
            self.section = section
        }
    }

    public struct WatchlistData: Equatable, Sendable {
        public let groupInCategories: Bool
        public let allItems: [WatchlistItem]
        public let visibleItems: [WatchlistItem]
    }
}

// MARK: - Helper Functions

private func sectioned(_ items: [WatchlistFeature.WatchlistItem]) -> [WatchlistFeature.SectionGroup] {
    Dictionary(grouping: items, by: \.section)
        .map { WatchlistFeature.SectionGroup(section: $0.key, items: $0.value) }
        .sorted { $0.section < $1.section }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
