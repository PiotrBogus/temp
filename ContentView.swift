import ComposableArchitecture
import GenieCommonPresentation
import SwiftUI

// PreferenceKey mierzący maksymalną wysokość treści (headerów i komórek)
private struct ContentHeightKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

public struct GraphTableView: View {
    @Bindable var store: StoreOf<GraphTableFeature>

    @State private var maxCellHeight: CGFloat = 44
    @State private var availableWidth: CGFloat = 0
    @State private var isScrolledToBottom: Bool = false

    private var isHorizontalScrollEnabled: Bool {
        let computedWidth = store.columnsWidth.reduce(0, +) + CGFloat(max(0, store.columns.count - 1)) * Constants.horizontalSpacing
        return computedWidth > availableWidth
    }

    private struct Constants {
        static let defaultColumnWidth: CGFloat = 80
        static let headerInnerPadding: CGFloat = 4
        static let horizontalSpacing: CGFloat = 8
        static let titleFont: Font = .footnote
        static let subtitleFont: Font = .caption
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
                    mainTable
                }
            }
            .onAppear { availableWidth = geo.size.width }
        }
        .background(Color.whiteBackground)
        .task { store.send(.onAppear) }
        .onPreferenceChange(ContentHeightKey.self) { newH in
            if newH > 0 && newH != maxCellHeight {
                maxCellHeight = newH
            }
        }
    }

    private var mainTable: some View {
        Group {
            if isHorizontalScrollEnabled {
                ScrollView([.vertical, .horizontal]) {
                    tableContent(evenly: false)
                }
            } else {
                ScrollView(.vertical) {
                    tableContent(evenly: true)
                        .frame(width: availableWidth)
                }
            }
        }
    }

    @ViewBuilder
    private func tableContent(evenly: Bool) -> some View {
        VStack(spacing: .zero) {
            titleBar()
            Divider()
            filterBar()

            // header section
            VStack(spacing: .zero) {
                Divider()

                HStack(alignment: .center, spacing: evenly ? 0 : Constants.horizontalSpacing) {
                    ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                        let alignment: HorizontalAlignment = index == 0 ? .leading : .trailing
                        if evenly {
                            headerCell(column.header, alignment: alignment)
                                .frame(maxWidth: .infinity)
                        } else {
                            headerCell(column.header, width: getColumnWidth(index: index), alignment: alignment)
                        }
                    }
                }
                .frame(height: maxCellHeight)

                Divider()
            }

            // data columns
            HStack(alignment: .top, spacing: evenly ? 0 : Constants.horizontalSpacing) {
                ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                    let alignment: HorizontalAlignment = index == 0 ? .leading : .trailing
                    if evenly {
                        columnView(items: column.items, alignment: alignment)
                            .frame(maxWidth: .infinity)
                    } else {
                        columnView(items: column.items, alignment: alignment, width: getColumnWidth(index: index))
                    }
                }
            }

            Spacer(minLength: 16)
        }
    }

    @ViewBuilder
    private func titleBar() -> some View {
        HStack {
            Text(store.tableTitle)
                .font(.headline)
            Spacer()
            Button { } label: {
                Image(systemName: "xmark").foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
    }

    @ViewBuilder
    private func filterBar() -> some View {
        HStack {
            Menu {
                ForEach(store.filters) { f in Button(f.title, action: {}) }
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

    @ViewBuilder
    private func headerCell(_ header: TableHeader, width: CGFloat? = nil, alignment: HorizontalAlignment) -> some View {
        HStack {
            if alignment == .trailing { Spacer(minLength: 0) }

            HStack(spacing: 4) {
                VStack(alignment: alignment, spacing: 2) {
                    Text(header.title)
                        .font(Constants.titleFont)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(Color.text)

                    if let subtitle = header.subtitle {
                        Text(subtitle)
                            .font(Constants.subtitleFont)
                            .italic()
                            .foregroundColor(Color.headerButtonSubtitle)
                            .lineLimit(1)
                    }
                }

                if header.isDropdown {
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color.text)
                        .font(Constants.subtitleFont)
                }
            }
            .padding(Constants.headerInnerPadding)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(header.isDropdown ? Color.headerBackround : Color.whiteBackground)
            )

            if alignment == .leading {
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, Constants.headerInnerPadding)
        .background(GeometryReader { proxy in
            Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
        })
        .frame(width: width, height: maxCellHeight, alignment: alignment == .leading ? .leading : .trailing)
    }

    @ViewBuilder
    private func columnView(items: [TableItem], alignment: HorizontalAlignment, width: CGFloat? = nil) -> some View {
        VStack(alignment: alignment, spacing: .zero) {
            ForEach(items.indices, id: \.self) { idx in
                let item = items[idx]
                HStack {
                    if alignment == .trailing { Spacer(minLength: 0) }

                    Text(item.title)
                        .font(Constants.titleFont)
                        .lineLimit(1)
                        .foregroundStyle(item.color)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
                        })

                    if alignment == .leading { Spacer(minLength: 0) }
                }
                .frame(height: maxCellHeight)

                if idx != items.count - 1 {
                    Divider().background(Color.secondary.opacity(0.1))
                }
            }
        }
        .frame(width: width.map { $0 + 12 })
    }

    private func getColumnWidth(index: Int) -> CGFloat {
        store.columnsWidth[safe: index] ?? Constants.defaultColumnWidth
    }
}

// safe index
extension Collection {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}



import ComposableArchitecture
import Foundation
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

    func calculateColumnsWidth(columns: [TableColumn]) -> Effect<Action> {
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
                        await ColumnWidthCalculator.maxWidth(for: titles, font: .footnote)
                    }
                }

                var results: [CGFloat] = []
                for await width in group {
                    results.append(width)
                }
                return results
            }

            let adjustedWidths = baseWidths.enumerated().map { index, width in
                let header = columns[index].header
                var adjusted = width + 16 // padding left + right
                if header.isDropdown {
                    adjusted += 12 // icon width + spacing
                }
                return adjusted
            }

            await send(.didCalculateColumnsWidth(adjustedWidths))
        }
    }
}
