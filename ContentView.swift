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
        var availableWidth: CGFloat = 0

        public init() {}
    }

    public enum Action: Sendable {
        case onAppear(CGFloat) // przekazujemy szerokość ekranu
        case didCalculateColumnsWidth([CGFloat])
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .onAppear(width):
                state.availableWidth = width
                return calculateColumnsWidth(columns: state.columns, availableWidth: width)

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
    func calculateColumnsWidth(columns: [TableColumn], availableWidth: CGFloat) -> Effect<Action> {
        .run { send in
            let widths = await computeAllColumnWidths(columns).map(\.0)
            let adjusted = adjustWidthsToFitScreen(widths, availableWidth: availableWidth)
            await send(.didCalculateColumnsWidth(adjusted))
        }
    }

    /// Oblicza wszystkie kolumny równolegle
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

    /// Oblicza szerokość pojedynczej kolumny
    private func computeSingleColumnWidth(_ column: TableColumn) async -> CGFloat {
        async let headerWidth = computeHeaderWidth(column.header)
        async let itemsWidth = computeItemsWidth(column.items)
        let (hWidth, iWidth) = await (headerWidth, itemsWidth)
        return max(hWidth, iWidth) + 2 * GraphTableConstants.smallPadding
    }

    /// Oblicza szerokość headera
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

    /// Oblicza szerokość wartości w kolumnie
    private func computeItemsWidth(_ items: [TableItem]) async -> CGFloat {
        let baseWidth = await ColumnWidthCalculator.maxWidth(for: items.map(\.title), font: .footnote)
        return baseWidth + 2 * GraphTableConstants.smallPadding
    }

    /// 🔥 Dopasowuje szerokości do ekranu (jeśli tabela jest węższa niż ekran)
    private func adjustWidthsToFitScreen(_ widths: [CGFloat], availableWidth: CGFloat) -> [CGFloat] {
        let total = widths.reduce(0, +)
        guard total < availableWidth, widths.count > 0 else { return widths }

        let extra = (availableWidth - total) / CGFloat(widths.count)
        return widths.map { $0 + extra }
    }
}
