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

            let baseWidths = await withTaskGroup(of: (CGFloat, Int).self) { group -> [(CGFloat, Int)] in
                titlesByColumns.enumerated().forEach { index, titles in
                    group.addTask {
                        let maxWidth = await ColumnWidthCalculator.maxWidth(for: titles, font: .footnote)
                        return (maxWidth, index)
                    }
                }

                var results: [(CGFloat, Int)] = []
                for await width in group {
                    results.append(width)
                }
                return results.sorted(by: { $0.1 < $1.1 })
            }

            let adjustedWidths = baseWidths.map { width, index in
                let header = columns[index].header
                var adjusted = width + 2 * GraphTableConstants.headerInnerPadding
                if header.isDropdown {
                    adjusted += GraphTableConstants.headerIconWidth + GraphTableConstants.headerImagePadding
                }
                return adjusted
            }

            await send(.didCalculateColumnsWidth(adjustedWidths))
        }
    }
}
