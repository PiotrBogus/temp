import SwiftUI
import ComposableArchitecture

public struct AlternativeViewScreen: View {

    let store: StoreOf<AlternativeViewFeature>

    public init(store: StoreOf<AlternativeViewFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {

                // LISTA
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEachStore(
                            store.scope(
                                state: \.items,
                                action: AlternativeViewFeature.Action.items
                            )
                        ) { itemStore in
                            AlternativeItemRowView(store: itemStore)
                        }
                    }
                    .padding(.top, 12)
                }

                Divider()

                // SEARCH
                searchBar
            }
            .navigationTitle("Watchlist Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewStore.send(.dismiss)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewStore.send(.delegate(.dismiss))
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .onAppear {
                viewStore.send(.onFirstAppear)
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            Text("Search Watchlist")
                .foregroundColor(.gray)

            Spacer()

            Image(systemName: "mic.fill")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}



struct AlternativeItemRowView: View {

    let store: StoreOf<AlternativeItemFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 0) {

                Button {
                    viewStore.send(.didTapItem(id: viewStore.id))
                } label: {
                    HStack(spacing: 8) {

                        IndentationView(
                            level: viewStore.level,
                            isExpandable: viewStore.isPossibleToExpand,
                            isExpanded: viewStore.isExpanded,
                            isSelected: viewStore.isSelected
                        )

                        Text(viewStore.title)
                            .foregroundColor(.primary)
                            .font(.system(size: 15))

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // DZIECI
                if viewStore.isExpanded {
                    ForEachStore(
                        store.scope(
                            state: \.identifiedArrayOfChildrens,
                            action: AlternativeItemFeature.Action.children
                        )
                    ) { childStore in
                        AlternativeItemRowView(store: childStore)
                    }
                }

                Divider()
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}
