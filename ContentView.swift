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

    // MARK: - Table Content
    private var tableView: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(spacing: 0) {
                headerView()
                Divider()
                filterView()
                Divider().padding(.bottom, 4)

                // ✅ Główna część tabeli
                HStack(alignment: .top, spacing: 8) {
                    ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                        VStack(spacing: 0) {
                            // Header komórki
                            tableHeaderCell(
                                for: store.headerItems[safe: index],
                                width: store.columnsWidth[safe: index] ?? 60,
                                alignment: index == 0 ? .leading : .trailing
                            )

                            Divider().background(Color.secondary.opacity(0.3))

                            // Kolumna danych
                            tableColumn(
                                for: column,
                                alignment: index == 0 ? .leading : .trailing,
                                width: store.columnsWidth[safe: index] ?? 60
                            )
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 16)
            }
        }
    }

    // MARK: - Header
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

    // MARK: - Single Header Cell
    @ViewBuilder
    func tableHeaderCell(for header: TableHeader?, width: CGFloat, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            if let header {
                HStack(alignment: .center, spacing: 4) {
                    VStack(alignment: alignment, spacing: 2) {
                        Text(header.title)
                            .font(.callout)
                            .fontWeight(.semibold)
                        if let subtitle = header.subtitle {
                            Text(subtitle)
                                .font(.footnote)
                                .italic()
                                .foregroundColor(.secondary)
                        }
                    }

                    if header.isDropdown {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: width, alignment: alignment == .leading ? .leading : .trailing)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(header.isDropdown ? Color.headerBackround : Color.whiteBackground)
                )
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: width, height: 30)
            }
        }
    }

    // MARK: - Table Column
    @ViewBuilder
    func tableColumn(for column: TableColumn, alignment: HorizontalAlignment, width: CGFloat) -> some View {
        VStack(alignment: alignment, spacing: 8) {
            ForEach(column.items) { item in
                Text(item.title)
                    .foregroundStyle(item.color)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
                    .padding(.horizontal, 4)

                Divider().background(Color.secondary.opacity(0.1))
            }
        }
        .frame(width: width + 12) // lekki margines dla czytelności
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
