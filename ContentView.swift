import ComposableArchitecture

@Reducer
public struct MenuGroupFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        public let id: String
        public var title: String
        public var items: [MenuItemModel]
        public var isExpanded: Bool = false

        public init(id: String, title: String, items: [MenuItemModel], isExpanded: Bool = false) {
            self.id = id
            self.title = title
            self.items = items
            self.isExpanded = isExpanded
        }
    }

    public enum Action: Equatable {
        case toggleExpanded
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .toggleExpanded:
                state.isExpanded.toggle()
                return .none
            }
        }
    }
}




public struct MenuGroupView: View {
    let store: StoreOf<MenuGroupFeature>
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    store.send(.toggleExpanded)
                } label: {
                    HStack(spacing: 4) {
                        Text(viewStore.title)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)

                        Image(systemName: viewStore.isExpanded ? "chevron.down" : "chevron.up")
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )

                if viewStore.isExpanded {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewStore.items) { item in
                            MenuItemView(model: item)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}




import SwiftUI
import ComposableArchitecture

public struct MenuView: View {
    let store: StoreOf<MenuFeature>

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    public init(store: StoreOf<MenuFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEachStore(
                    store.scope(state: \.groups, action: \.group)
                ) { groupStore in
                    MenuGroupView(store: groupStore)
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            store.send(.onFirstAppear)
        }
    }
}





import ComposableArchitecture

@Reducer
public struct MenuFeature {
    @ObservableState
    public struct State: Equatable {
        var groups: IdentifiedArrayOf<MenuGroupFeature.State> = []
    }

    public enum Action: Equatable {
        case onFirstAppear
        case didLoadMenu([MenuGroupModel])
        case group(id: MenuGroupFeature.State.ID, action: MenuGroupFeature.Action)
        case dismiss
    }

    @Dependency(\.menuFeatureClient.loadMenuItems) var loadMenuItems
    @Dependency(\.menuFeatureClient.log) var log

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onFirstAppear:
                log(.debug, "menu did appear for first time")
                return .run { send in
                    let groups = try? await loadMenuItems()
                    let states = (groups ?? []).map {
                        MenuGroupFeature.State(id: $0.id, title: $0.title, items: $0.items)
                    }
                    await send(.didLoadMenu(states))
                }

            case let .didLoadMenu(groups):
                state.groups = IdentifiedArrayOf(uniqueElements: groups)
                return .none

            case .group:
                return .none

            case .dismiss:
                return .none
            }
        }
        .forEach(\.groups, action: \.group) {
            MenuGroupFeature()
        }
    }
}
