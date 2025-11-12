import ComposableArchitecture
import GenieCommonPresentation
import SwiftUI

public struct GraphTableView: View {
    @Bindable var store: StoreOf<GraphTableFeature>

    private struct Constants {
        static let cellHeight: CGFloat = 44
        static let defaultColumnWidth: CGFloat = 80
        static let headerInnerPadding: CGFloat = 4
        static let horizontalSpacing: CGFloat = 8
    }

    @State private var totalTableWidth: CGFloat = 0
    @State private var availableWidth: CGFloat = 0

    public init(store: StoreOf<GraphTableFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch store.contentViewState {
                case .loader:
                    LoaderView()
                case .table:
                    tableView(availableWidth: geometry.size.width)
                }
            }
            .onAppear {
                availableWidth = geometry.size.width
            }
        }
        .background(Color.whiteBackground)
        .task {
            store.send(.onAppear)
        }
    }

    // MARK: - Table
    private func tableView(availableWidth: CGFloat) -> some View {
        // 🔹 wyliczamy szerokość całkowitą tabeli
        let computedWidth = store.columnsWidth.reduce(0, +) + CGFloat(store.columns.count - 1) * Constants.horizontalSpacing
        let needsHorizontalScroll = computedWidth > availableWidth

        return Group {
            if needsHorizontalScroll {
                ScrollView([.vertical, .horizontal]) {
                    tableContent()
                }
            } else {
                // 🔹 jeśli tabela mieści się na ekranie — nie przewijamy poziomo
                ScrollView(.vertical) {
                    tableContent(evenlyDistributed: true)
                        .frame(width: availableWidth)
                }
            }
        }
    }

    // MARK: - Table Content
    @ViewBuilder
    private func tableContent(evenlyDistributed: Bool = false) -> some View {
        VStack(spacing: .zero) {
            headerView()
            Divider()
            filterView()

            // ✅ header section
            VStack(spacing: .zero) {
                Divider()

                HStack(alignment: .center, spacing: evenlyDistributed ? 0 : Constants.horizontalSpacing) {
                    ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                        let width = evenlyDistributed
                            ? nil // kolumna rozciąga się równomiernie
                            : getColumnWidth(index: index)

                        tableHeaderCell(
                            for: column.header,
                            width: width,
                            alignment: index == 0 ? .leading : .trailing
                        )
                        .frame(maxWidth: evenlyDistributed ? .infinity : nil)
                    }
                }
                .frame(height: Constants.cellHeight)

                Divider()
            }

            // ✅ columns section
            HStack(alignment: .top, spacing: evenlyDistributed ? 0 : Constants.horizontalSpacing) {
                ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                    let width = evenlyDistributed
                        ? nil
                        : getColumnWidth(index: index)

                    tableColumn(
                        for: column.items,
                        alignment: index == 0 ? .leading : .trailing,
                        width: width
                    )
                    .frame(maxWidth: evenlyDistributed ? .infinity : nil)
                }
            }

            Spacer(minLength: 16)
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
    func tableHeaderCell(for header: TableHeader, width: CGFloat?, alignment: HorizontalAlignment) -> some View {
        VStack {
            HStack(spacing: 4) {
                VStack(alignment: alignment, spacing: 2) {
                    Text(header.title)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .minimumScaleFactor(0.7) // ✅ zamiast ellipsy
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = header.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .italic()
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
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
    func tableColumn(for items: [TableItem], alignment: HorizontalAlignment, width: CGFloat?) -> some View {
        VStack(alignment: alignment, spacing: .zero) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                VStack(spacing: .zero) {
                    Text(item.title)
                        .foregroundStyle(item.color)
                        .font(.footnote)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
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
        .frame(width: width.map { $0 + 12 })
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
