import ComposableArchitecture
import GenieCommonPresentation
import SwiftUI

public struct GraphTableView: View {
    @Bindable var store: StoreOf<GraphTableFeature>

    public init(store: StoreOf<GraphTableFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            switch store.contentViewState {
            case .loader:
                LoaderView()
            case .table:
                tableView
            }
        }
        .background(Color.whiteBackground)
        .task {
            store.send(.onAppear)
        }
    }

    // MARK: - Table
    private var tableView: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(spacing: 0) {
                headerView()
                Divider()
                filterView()
                Divider().padding(.bottom, 4)

                // ✅ Sekcja nagłówków kolumn
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                        tableHeaderCell(
                            for: column.header,
                            width: store.columnsWidth[safe: index] ?? 80,
                            alignment: index == 0 ? .leading : .trailing
                        )
                    }
                }
                .padding(.horizontal)
                Divider().padding(.bottom, 4)

                // ✅ Sekcja wierszy
                HStack(alignment: .top, spacing: 8) {
                    ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                        tableColumn(
                            for: column.items,
                            alignment: index == 0 ? .leading : .trailing,
                            width: store.columnsWidth[safe: index] ?? 80
                        )
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 16)
            }
        }
    }

    // MARK: - Header (tytuł tabeli)
    @ViewBuilder
    func headerView() -> some View {
        HStack {
            Text(store.tableTitle)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button(action: {}) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
    }

    // MARK: - Filter
    @ViewBuilder
    func filterView() -> some View {
        HStack {
            Menu {
                ForEach(store.filters) { filter in
                    Button(filter.title, action: {})
                }
            } label: {
                HStack {
                    Text("KPI +1")
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.filter)
                .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Table Header Cell
    @ViewBuilder
    func tableHeaderCell(for header: TableHeader, width: CGFloat, alignment: HorizontalAlignment) -> some View {
        HStack(spacing: 4) {
            VStack(alignment: alignment, spacing: 2) {
                Text(header.title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                if let subtitle = header.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .italic()
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            if header.isDropdown {
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: width, alignment: alignment == .leading ? .leading : .trailing)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(header.isDropdown ? Color.headerBackround : Color.whiteBackground)
        )
    }

    // MARK: - Table Column (Items)
    @ViewBuilder
    func tableColumn(for items: [TableItem], alignment: HorizontalAlignment, width: CGFloat) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            ForEach(items) { item in
                Text(item.title)
                    .foregroundStyle(item.color)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
                    .frame(height: 32) // ✅ stała wysokość każdego wiersza
                    .padding(.horizontal, 4)

                Divider().background(Color.secondary.opacity(0.1))
            }
        }
        .frame(width: width + 12)
    }
}

// MARK: - Safe index helper
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview
#Preview {
    GraphTableView(store: Store(initialState: GraphTableFeature.State()) {
        GraphTableFeature()
    })
}
