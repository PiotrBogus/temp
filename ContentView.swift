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
}


// MARK: - Column width calculation logic
private extension GraphTableFeature {
    func calculateColumnsWidth(columns: [TableColumn]) -> Effect<Action> {
        .run { send in
            let widths = await computeAllColumnWidths(columns).map(\.0)
            await send(.didCalculateColumnsWidth(widths))
        }
    }

    private func computeAllColumnWidths(_ columns: [TableColumn]) async -> [(CGFloat, Int)] {
        await withTaskGroup(of: (CGFloat, Int).self) { group -> [(CGFloat, Int)] in
            for (index, column) in columns.enumerated() {
                group.addTask {
                    let width = await computeSingleColumnWidth(column)
                    return (width, index)
                }
            }

            var results: [(CGFloat, Int)] = []
            for await result in group { results.append(result) }

            return results.sorted(by: { $0.1 < $1.1 })
        }
    }

    private func computeSingleColumnWidth(_ column: TableColumn) async -> CGFloat {
        async let headerWidth = computeHeaderWidth(column.header)
        async let itemsWidth = computeItemsWidth(column.items)

        let (hWidth, iWidth) = await (headerWidth, itemsWidth)
        return max(hWidth, iWidth)
    }

    private func computeHeaderWidth(_ header: TableHeader) async -> CGFloat {
        var texts = [header.title]
        if let subtitle = header.subtitle {
            texts.append(subtitle)
        }

        let baseWidth = await ColumnWidthCalculator.maxWidth(for: texts, font: .footnote)

        var adjusted = baseWidth + 4 * GraphTableConstants.smallPadding
        if header.isDropdown {
            adjusted += GraphTableConstants.headerIconWidth + 2 * GraphTableConstants.smallPadding
        }

        return adjusted
    }

    private func computeItemsWidth(_ items: [TableItem]) async -> CGFloat {
        let baseWidth = await ColumnWidthCalculator.maxWidth(for: items.map(\.title), font: .footnote)
        return baseWidth + 2 * GraphTableConstants.smallPadding
    }
}





import ComposableArchitecture
import GenieCommonPresentation
import SwiftUI

private struct ContentHeightKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct GraphTableConstants {
    static let defaultColumnWidth: CGFloat = 80
    static let smallPadding: CGFloat = 4
    static let horizontalSpacing: CGFloat = 8
    static let titleFont: Font = .footnote
    static let subtitleFont: Font = .caption
    static let headerIconWidth: CGFloat = 13
    static let headerIconHeight: CGFloat = 8
}

public struct GraphTableView: View {
    @Bindable var store: StoreOf<GraphTableFeature>

    @State private var maxCellHeight: CGFloat = 44
    @State private var availableWidth: CGFloat = 0
    @State private var isScrolledToBottom: Bool = false

    private var isHorizontalScrollEnabled: Bool {
        let computedWidth = store.columnsWidth.reduce(0, +) + CGFloat(max(0, store.columns.count - 1)) * GraphTableConstants.horizontalSpacing
        return computedWidth > availableWidth
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
            .onAppear {
                availableWidth = geo.size.width
            }
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

                HStack(alignment: .center, spacing: .zero) {
                    ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                        let alignment: HorizontalAlignment = index == 0 ? .leading : .trailing
                        headerCell(
                            column.header,
                            width: getColumnWidth(index: index),
                            alignment: alignment
                        )
                    }
                }

                Divider()
            }

            // data columns
            HStack(alignment: .top, spacing: .zero) {
                ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, column in
                    let alignment: HorizontalAlignment = index == 0 ? .leading : .trailing
                    columnView(
                        items: column.items,
                        alignment: alignment,
                        width: getColumnWidth(index: index)
                    )
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
        HStack(spacing: .zero) {
            if alignment == .trailing {
                Spacer()
            }

            HStack(spacing: GraphTableConstants.smallPadding) {
                VStack(alignment: alignment, spacing: 2) {
                    Text(header.title)
                        .font(GraphTableConstants.titleFont)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(Color.text)

                    if let subtitle = header.subtitle {
                        Text(subtitle)
                            .font(GraphTableConstants.subtitleFont)
                            .italic()
                            .foregroundColor(Color.headerButtonSubtitle)
                            .lineLimit(1)
                    }
                }

                if header.isDropdown {
                    Image(systemName: "chevron.down")
                        .resizable()
                        .foregroundColor(Color.text)
                        .font(GraphTableConstants.subtitleFont)
                        .frame(width: GraphTableConstants.headerIconWidth, height: GraphTableConstants.headerIconHeight)
                }
            }
            .padding(.all, GraphTableConstants.smallPadding)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(header.isDropdown ? Color.headerBackround : Color.whiteBackground)
            )

            if alignment == .leading {
                Spacer()
            }
        }
        .padding(.vertical, GraphTableConstants.smallPadding)
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
                HStack(spacing: .zero) {
                    if alignment == .trailing {
                        Spacer()
                    }

                    Text(item.title)
                        .font(GraphTableConstants.titleFont)
                        .lineLimit(1)
                        .foregroundStyle(item.color)
                        .padding(.horizontal, GraphTableConstants.smallPadding)
                        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
                        })

                    if alignment == .leading {
                        Spacer()
                    }
                }
                .frame(height: maxCellHeight)

                if idx != items.count - 1 {
                    Divider().background(Color.secondary.opacity(0.1))
                }
            }
        }
        .frame(width: width)
    }

    private func getColumnWidth(index: Int) -> CGFloat {
        store.columnsWidth[safe: index] ?? GraphTableConstants.defaultColumnWidth
    }
}

// safe index
extension Collection {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
