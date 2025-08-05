import SwiftUI
import ComposableArchitecture

public struct MenuView: View {
    @Bindable var store: StoreOf<MenuFeature>

    public init(store: StoreOf<MenuFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(
                    store.scope(
                        state: \.items,
                        action: \.items
                    ),
                    id: \.state.id
                ) {
                    MenuItemView(store: $0)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            store.send(.onFirstAppear)
        }
        .background(
            Asset.Assets.primary.swiftUIColor
        )
    }
}

struct MenuItemView: View {
    let store: StoreOf<MenuItemFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            button

            if store.isPossibleToExpand,
               store.isExpanded {
                childrensView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Asset.Assets.rowBlue.swiftUIColor)
        )
    }

    private var button: some View {
        Button(action: {
            store.send(.didTapItem(id: store.id))
        }, label: {
            HStack {
                Text(store.title)
                    .font(.body)
                    .foregroundStyle(Color.white)

                Spacer()

                if store.isPossibleToExpand {
                    Image(systemName: store.isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.horizontal, 16)
        })
        .frame(height: 48)
    }

    private var childrensView: some View {
        VStack {
            ForEach(
                store.scope(
                    state: \.childrens,
                    action: \.childrens
                ),
                id: \.state.id
            ) {
                MenuItemView(store: $0)
                    .padding(.horizontal, 16)
            }
            .padding(.leading, 16)
        }
    }
}


import Foundation
import ComposableArchitecture

@Reducer
public struct MenuItemFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Identifiable {
        public let id: String
        let title: String
        let parentId: String?
        var childrens: IdentifiedArrayOf<MenuItemFeature.State>
        var isExpanded: Bool = false
        var isSelected: Bool = false

        var isPossibleToExpand: Bool {
            childrens.isEmpty == false
        }

        mutating func attachChildrens(newValue: IdentifiedArrayOf<MenuItemFeature.State>) {
            childrens = newValue
        }
    }

    public indirect enum Action {
        case didTapItem(id: String)
        case childrens(IdentifiedActionOf<MenuItemFeature>)
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .didTapItem(id):
//                log(.debug, "did tap item: \(id)")
                if state.isPossibleToExpand {
                    state.isExpanded = !state.isExpanded
                }
                return .none
            case .childrens:
                return .none
            }
        }
    }
}

extension MenuItemFeature {
    public enum Delegate: Sendable, Equatable {}
}
