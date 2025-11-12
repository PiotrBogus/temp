import SwiftUI

public enum GraphTableConstants {
    public static let defaultColumnWidth: CGFloat = 80
    public static let headerInnerPadding: CGFloat = 4
    public static let horizontalSpacing: CGFloat = 8
    public static let titleFont: Font = .footnote
    public static let subtitleFont: Font = .caption
    public static let horizontalTextPadding: CGFloat = 8
    public static let dropdownIconWidth: CGFloat = 12
}


import ComposableArchitecture
import Foundation
import SwiftUI
import GenieCommonPresentation

@Reducer
public struct GraphTableFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        enum ContentViewState: Equatable, Sendable {
            case loader
            case table
        }

        var contentViewState: ContentViewState = .loader
        var tableTitle: String = "Patient Share/US/Entresto"
        var filters: [GraphTableFilter] = GraphTableFilter.mock
        var columns: [TableColumn] = TableColumn.mock
        var columnsWidth: [CGFloat] = []

        public init() {}
    }

    public enum Action: Sendable {
        case onAppear
        case didCalculateColumnsWidth([CGFloat])
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return calculateColumnsWidth(columns: state.columns)
            case let .didCalculateColumnsWidth(widths):
                state.columnsWidth = widths
                state.contentViewState = .table
                return .none
            }
        }
    }

    private func calculateColumnsWidth(columns: [TableColumn]) -> Effect<Action> {
        .run { send in
            let titlesByColumns: [[String]] = columns.map { column in
                var titles = column.items.map(\.title)
                titles.append(column.header.title)
                if let subtitle = column.header.subtitle {
                    titles.append(subtitle)
                }
                return titles
            }

            let baseWidths = await withTaskGroup(of: CGFloat.self) { group -> [CGFloat] in
                for titles in titlesByColumns {
                    group.addTask {
                        await ColumnWidthCalculator.maxWidth(for: titles, font: GraphTableConstants.titleFont)
                    }
                }

                var results: [CGFloat] = []
                for await width in group {
                    results.append(width)
                }
                return results
            }

            // 🧮 dodajemy padding + ikonkę (zgodnie z widokiem)
            let adjustedWidths = baseWidths.enumerated().map { index, width in
                let header = columns[index].header
                var adjusted = width + (GraphTableConstants.horizontalTextPadding * 2)
                if header.isDropdown {
                    adjusted += GraphTableConstants.dropdownIconWidth + GraphTableConstants.headerInnerPadding
                }
                return adjusted
            }

            await send(.didCalculateColumnsWidth(adjustedWidths))
        }
    }
}



import ComposableArchitecture
import GenieCommonPresentation
import SwiftUI

public struct GraphTableView: View {
    @Bindable var store: StoreOf<GraphTableFeature>

    @State private var maxCellHeight: CGFloat = 44
    @State private var availableWidth: CGFloat = 0

    private var isHorizontalScrollEnabled: Bool {
        let totalWidth = store.columnsWidth.reduce(0, +)
        let spacing = CGFloat(max(0, store.columns.count - 1)) * GraphTableConstants.horizontalSpacing
        return totalWidth + spacing > availableWidth
    }

    public init(store: StoreOf<GraphTableFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                switch store.contentViewState {
                case .loader:
                    LoaderView()
                case .table:
                    tableView
                }
            }
            .onAppear { availableWidth = geo.size.width }
        }
        .background(Color.whiteBackground)
        .task { store.send(.onAppear) }
    }

    // MARK: - Table
    private var tableView: some View {
        Group {
            if isHorizontalScrollEnabled {
                ScrollView([.vertical, .horizontal]) {
                    contentView(evenly: false)
                }
            } else {
                ScrollView(.vertical) {
                    contentView(evenly: true)
                        .frame(width: availableWidth)
                }
            }
        }
    }

    // MARK: - Content
    @ViewBuilder
    private func contentView(evenly: Bool) -> some View {
        VStack(spacing: 0) {
            headerBar()
            Divider()
            filterBar()

            // Header
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: evenly ? 0 : GraphTableConstants.horizontalSpacing) {
                    ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                        let alignment: HorizontalAlignment = index == 0 ? .leading : .trailing
                        headerCell(column.header, width: evenly ? nil : getColumnWidth(index: index), alignment: alignment)
                            .frame(maxWidth: evenly ? .infinity : nil)
                    }
                }
                .frame(height: maxCellHeight)
                Divider()
            }

            // Rows
            HStack(alignment: .top, spacing: evenly ? 0 : GraphTableConstants.horizontalSpacing) {
                ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                    let alignment: HorizontalAlignment = index == 0 ? .leading : .trailing
                    columnView(column.items, width: evenly ? nil : getColumnWidth(index: index), alignment: alignment)
                        .frame(maxWidth: evenly ? .infinity : nil)
                }
            }

            Spacer(minLength: 16)
        }
    }

    // MARK: - Header Bar
    @ViewBuilder
    private func headerBar() -> some View {
        HStack {
            Text(store.tableTitle)
                .font(.headline)
            Spacer()
            Button(action: {}) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
    }

    // MARK: - Filter Bar
    @ViewBuilder
    private func filterBar() -> some View {
        HStack {
            Menu {
                ForEach(store.filters) { filter in
                    Button(filter.title, action: {})
                }
            } label: {
                HStack {
                    Text("KPI +1")
                    Image(systemName: "chevron.down").font(.caption)
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

    // MARK: - Header Cell
    @ViewBuilder
    private func headerCell(_ header: TableHeader, width: CGFloat?, alignment: HorizontalAlignment) -> some View {
        HStack {
            if alignment == .trailing { Spacer(minLength: 0) }

            HStack(spacing: GraphTableConstants.headerInnerPadding) {
                VStack(alignment: alignment, spacing: 2) {
                    Text(header.title)
                        .font(GraphTableConstants.titleFont)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    if let subtitle = header.subtitle {
                        Text(subtitle)
                            .font(GraphTableConstants.subtitleFont)
                            .italic()
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                if header.isDropdown {
                    Image(systemName: "chevron.down")
                        .font(GraphTableConstants.subtitleFont)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, GraphTableConstants.horizontalTextPadding)
            .padding(.vertical, GraphTableConstants.headerInnerPadding)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(header.isDropdown ? Color.headerBackround : Color.whiteBackground)
                    .padding(-GraphTableConstants.headerInnerPadding)
            )

            if alignment == .leading { Spacer(minLength: 0) }
        }
        .frame(width: width, height: maxCellHeight, alignment: .center)
    }

    // MARK: - Column
    @ViewBuilder
    private func columnView(_ items: [TableItem], width: CGFloat?, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                HStack {
                    if alignment == .trailing { Spacer(minLength: 0) }

                    Text(item.title)
                        .font(GraphTableConstants.titleFont)
                        .foregroundStyle(item.color)
                        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
                        .padding(.horizontal, GraphTableConstants.horizontalTextPadding)
                        .frame(height: maxCellHeight)

                    if alignment == .leading { Spacer(minLength: 0) }
                }

                if index != items.count - 1 {
                    Divider().background(Color.secondary.opacity(0.1))
                }
            }
        }
        .frame(width: width)
    }

    // MARK: - Helpers
    private func getColumnWidth(index: Int) -> CGFloat {
        store.columnsWidth[safe: index] ?? GraphTableConstants.defaultColumnWidth
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
