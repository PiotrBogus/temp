import ComposableArchitecture
import GenieCommonPresentation
import SwiftUI

public struct GraphTableView: View {
    @Bindable var store: StoreOf<GraphTableFeature>

    private struct Constants {
        static let cellHeight: CGFloat = 44
        static let defaultColumnWidth: CGFloat = 80
        static let headerInnerPadding: CGFloat = 4
    }

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
            VStack(spacing: .zero) {
                headerView()
                Divider()
                filterView()

                // ✅ header
                VStack(spacing: .zero) {
                    Divider()

                    HStack(alignment: .center, spacing: .zero) {
                        ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                            tableHeaderCell(
                                for: column.header,
                                width: getColumnWidth(index: index),
                                alignment: index == 0 ? .leading : .trailing
                            )
                        }
                    }
                    .frame(height: Constants.cellHeight)

                    Divider()
                }

                // ✅ columns section
                HStack(alignment: .top, spacing: .zero) {
                    ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                        tableColumn(
                            for: column.items,
                            alignment: index == 0 ? .leading : .trailing,
                            width: getColumnWidth(index: index)
                        )
                    }
                }

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
        VStack {
            HStack(spacing: 4) {
                VStack(alignment: alignment, spacing: 2) {
                    Text(header.title)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    if let subtitle = header.subtitle {
                        Text(subtitle)
                            .font(.caption)
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
            .padding(Constants.headerInnerPadding)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(header.isDropdown ? Color.headerBackround : Color.whiteBackground)
            )
        }
        .frame(width: width, height: Constants.cellHeight, alignment: alignment == .leading ? .leading : .trailing)
    }

    // MARK: - Table Column (Items)
    @ViewBuilder
    func tableColumn(for items: [TableItem], alignment: HorizontalAlignment, width: CGFloat) -> some View {
        VStack(alignment: alignment, spacing: .zero) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                VStack(spacing: .zero) {
                    Text(item.title)
                        .foregroundStyle(item.color)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
                        .frame(height: Constants.cellHeight)
                        .padding(.horizontal, 4)

                    if index != items.indices.last {
                        Divider()
                            .background(Color.secondary.opacity(0.1))
                    }
                }
            }
        }
        .frame(width: width + 12)
    }

    private func getColumnWidth(index: Int) -> CGFloat {
        store.columnsWidth[safe: index] ?? Constants.defaultColumnWidth
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
