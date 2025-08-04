import Foundation
import ComposableArchitecture

@Reducer
public struct MenuFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        var items: IdentifiedArrayOf<MenuItemModel> = []

        public init() {}
    }

    public enum Action {
        case delegate(Delegate)
        case onFirstAppear
        case didLoadMenu([MenuItemModel])
        case dismiss
        case didTapItem(id: String)
    }

    @Dependency(\.menuFeatureClient.log) private var log
    @Dependency(\.menuFeatureClient.loadMenuItems) private var loadMenuItems

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onFirstAppear:
                log(.debug, "menu did appear for first time")
                return loadMenu()
            case let .didLoadMenu(items):
                log(.debug, "did load menu")
                state.items = IdentifiedArrayOf(uniqueElements: items)
                return .none
            case .delegate:
                return .none
            case .dismiss:
                return .none
            case let .didTapItem(id):
                log(.debug, "did tap item: \(id)")
                guard let item = state.items.first(where: { $0.id == id }) else {
                    return .none
                }
                item.isExpanded = !item.isExpanded

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



import SwiftUI
import ComposableArchitecture

public struct MenuView: View {
    @Bindable var store: StoreOf<MenuFeature>

    public init(store: StoreOf<MenuFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(store.items) {
                    itemView($0)
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            store.send(.onFirstAppear)
        }
    }

    private func itemView(_ model: MenuItemModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            button(model: model)

            if model.isPossibleToExpand,
               model.isExpanded {
                childrensView(model: model)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func button(model: MenuItemModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(model.title)
                    .font(.body)

                if model.isPossibleToExpand {
                    Button(action: {
                        store.send(.didTapItem(id: model.id))
                    }, label: {
                        Image(systemName: model.isExpanded ? "chevron.down" : "chevron.right")
                    })
                }
            }
            .frame(height: 48)
        }
    }

    private func childrensView(model: MenuItemModel) -> some View {
        VStack {
            ForEach(model.childrens) { _ in
//                itemView($0)
            }
            .padding(.leading, 16)
        }
    }
}


import Foundation

public class MenuItemModel: Identifiable, Equatable, @unchecked Sendable {
    public let id: String
    let title: String
    let parentId: String?
    var childrens: [MenuItemModel]
    var isPossibleToExpand: Bool {
        childrens.isEmpty == false
    }
    var isExpanded: Bool

    public init(id: String, title: String, parentId: String? = nil, childrens: [MenuItemModel] = [], isExpanded: Bool = false) {
        self.id = id
        self.title = title
        self.parentId = parentId
        self.childrens = childrens
        self.isExpanded = isExpanded
    }

    public static func == (lhs: MenuItemModel, rhs: MenuItemModel) -> Bool {
        lhs.isExpanded == rhs.isExpanded &&
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.parentId == rhs.parentId &&
        lhs.childrens == rhs.childrens
    }
}
