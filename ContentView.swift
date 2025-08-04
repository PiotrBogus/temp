import ComposableArchitecture
import SwiftUI

public struct MenuView: View {
    @Bindable var store: StoreOf<MenuFeature>

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    public init(store: StoreOf<MenuFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(store.groups) { model in
                    expandableButton(model: model)

                    if model.isExpanded {
                        verticalColumnView(model.items)
                    }
                }
            }
            .padding(.vertical)
        }
        .onFirstAppear {
            store.send(.onFirstAppear)
        }
    }

    private func expandableButton(model: MenuGroupModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                store.send(.didTapGroupHeader(id: model.id))
            }, label: {
                HStack(spacing: 4) {
                    Text(model.title)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)

                    Image(systemName: model.isExpanded ? "chevron.down" : "chevron.up")
                }
            })
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func verticalColumnView(_ items: [MenuItemModel]) -> some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { item in
                MenuItemView(model: item)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    MenuView(store: Store(initialState: MenuFeature.State()) {
        MenuFeature()
    })
}


import Foundation
import ComposableArchitecture

@Reducer
public struct MenuFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        var groups: IdentifiedArrayOf<MenuGroupModel> = []

        public init() {}
    }

    public enum Action {
        case delegate(Delegate)
        case onFirstAppear
        case didLoadMenu([MenuGroupModel])
        case dismiss
        case didTapGroupHeader(id: String)
    }

    @Dependency(\.menuFeatureClient.log) private var log
    @Dependency(\.menuFeatureClient.loadMenuItems) private var loadMenuItems

    public var body: some Reducer<State, Action> {
        Reduce {
            state,
            action in
            switch action {
            case .onFirstAppear:
                log(.debug, "menu did appear for first time")
                return loadMenu()
            case let .didLoadMenu(groups):
                log(.debug, "did load menu")
                state.groups = IdentifiedArrayOf(uniqueElements: groups)
                return .none
            case .delegate:
                return .none
            case .dismiss:
                return .none
            case let .didTapGroupHeader(id):
                log(.debug, "did tap group header: \(id)")
                let index = state.groups.firstIndex(where: { $0.id == id })
                guard let index else {
                    return .none
                }
                let oldItem = state.groups[index]
                state.groups[index] = MenuGroupModel(
                        id: oldItem.id,
                        title: oldItem.title,
                        items: oldItem.items,
                        isExpanded: !oldItem.isExpanded
                    )
            
                return .none
            }
        }
    }
}

extension MenuFeature {
    public enum Delegate: Sendable, Equatable {}
}

private extension MenuFeature {
    private func loadMenu() -> Effect<Action> {
        return .run { send in
            let groups = try? await loadMenuItems()
            await send(.didLoadMenu(groups ?? []))
        }
    }
}
