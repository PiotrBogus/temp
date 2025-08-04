import ComposableArchitecture
import Foundation

@Reducer
struct ItemTreeFeature {
    struct State: Equatable, Identifiable {
        let id: String
        var title: String
        var platform: [String]
        var isExpanded: Bool = false
        var children: IdentifiedArrayOf<State> = []
    }

    enum Action {
        case toggleExpand
        case child(id: State.ID, action: Action)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .toggleExpand:
                state.isExpanded.toggle()
                return .none

            case let .child(id, action):
                return .none
            }
        }
        .forEach(\.children, action: \.child) {
            Self()
        }
    }
}
✅ 2. Tree Builder From JSON
Assuming you still have a decodable model:

swift
Kopiuj
Edytuj
struct Item: Decodable {
    let id: String
    let title: String
    let parentId: String?
    let platform: [String]?
}
Now convert flat Item list to ItemTreeFeature.State tree:

swift
Kopiuj
Edytuj
func buildTree(from flatItems: [Item]) -> IdentifiedArrayOf<ItemTreeFeature.State> {
    var lookup: [String: ItemTreeFeature.State] = [:]
    var roots: IdentifiedArrayOf<ItemTreeFeature.State> = []

    // First pass: create nodes
    for item in flatItems {
        let node = ItemTreeFeature.State(
            id: item.id,
            title: item.title,
            platform: item.platform ?? []
        )
        lookup[item.id] = node
    }

    // Second pass: build relationships
    for item in flatItems {
        guard let node = lookup[item.id] else { continue }

        if let parentId = item.parentId, var parent = lookup[parentId] {
            parent.children.append(node)
            lookup[parentId] = parent
        } else {
            roots.append(node)
        }
    }

    // Fix children relationship (rebuild to preserve identity)
    func attachChildren(to node: ItemTreeFeature.State) -> ItemTreeFeature.State {
        var updated = node
        updated.children = IdentifiedArray(uniqueElements: node.children.map {
            attachChildren(to: lookup[$0.id] ?? $0)
        })
        return updated
    }

    return IdentifiedArray(uniqueElements: roots.map { attachChildren(to: $0) })
}
✅ 3. SwiftUI View: ItemTreeView
swift
Kopiuj
Edytuj
import SwiftUI
import ComposableArchitecture

struct ItemTreeView: View {
    let store: StoreOf<ItemTreeFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if !viewStore.children.isEmpty {
                        Button(action: {
                            viewStore.send(.toggleExpand)
                        }) {
                            Image(systemName: viewStore.isExpanded ? "chevron.down" : "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }

                    Text(viewStore.title)
                        .font(.body)
                }

                if viewStore.isExpanded {
                    ForEachStore(
                        store.scope(state: \.children, action: \.child),
                        content: ItemTreeView.init(store:)
                    )
                    .padding(.leading, 16)
                }
            }
        }
    }
}
✅ 4. Root Feature & View
swift
Kopiuj
Edytuj
@Reducer
struct TreeRootFeature {
    struct State: Equatable {
        var roots: IdentifiedArrayOf<ItemTreeFeature.State> = []
    }

    enum Action {
        case root(id: ItemTreeFeature.State.ID, action: ItemTreeFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.roots, action: \.root) {
            ItemTreeFeature()
        }
    }
}
swift
Kopiuj
Edytuj
struct TreeRootView: View {
    let store: StoreOf<TreeRootFeature>

    var body: some View {
        WithViewStore(store, observe: { _ in }) { _ in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEachStore(
                        store.scope(state: \.roots, action: \.root),
                        content: ItemTreeView.init(store:)
                    )
                }
                .padding()
            }
        }
    }
}
✅ 5. Usage in ContentView
swift
Kopiuj
Edytuj
struct ContentView: View {
    @State var store: StoreOf<TreeRootFeature>

    init() {
        let items: [Item] = loadItems() // Load JSON
        let tree = buildTree(from: items)
        self.store = Store(initialState: TreeRootFeature.State(roots: tree)) {
            TreeRootFeature()
        }
    }

    var body: some View {
        TreeRootView(store: store)
    }

    func loadItems() -> [Item] {
        guard let url = Bundle.main.url(forResource: "yourFile", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([Item].self, from: data) else {
            return []
        }
        return items
    }
}
