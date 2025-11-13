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
        return max(hWidth, iWidth) + 2 * GraphTableConstants.smallPadding
    }

    private func computeHeaderWidth(_ header: TableHeader) async -> CGFloat {
        var texts = [header.title]
        if let subtitle = header.subtitle {
            texts.append(subtitle)
        }

        let baseWidth = await ColumnWidthCalculator.maxWidth(for: texts, font: .footnote, weight: .semibold)

        var adjusted = baseWidth + 2 * GraphTableConstants.smallPadding
        if header.isDropdown {
            adjusted += GraphTableConstants.headerIconWidth + GraphTableConstants.smallPadding
        }

        return adjusted
    }

    private func computeItemsWidth(_ items: [TableItem]) async -> CGFloat {
        let baseWidth = await ColumnWidthCalculator.maxWidth(for: items.map(\.title), font: .footnote)
        return baseWidth + 2 * GraphTableConstants.smallPadding
    }
}
