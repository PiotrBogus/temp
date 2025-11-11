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
        var headerItems: [TableHeader] = TableHeader.mock
        var rows: [TableRow] = TableRow.mock
        var columns: [TableColumn] {
            rows.transposed()
        }
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
            let titlesByColumns: [[String]] = columns.map { $0.items.map(\.title) }

            let widths = await withTaskGroup(of: CGFloat.self) { group -> [CGFloat] in
                titlesByColumns.forEach { titles in
                    group.addTask {
                        await ColumnWidthCalculator.maxWidth(for: titles, font: .callout)
                    }
                }
                var results: [CGFloat] = []
                for await width in group {
                    results.append(width)
                }
                return results
            }

            await send(.didCalculateColumnsWidth(widths))
        }
    }
}







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

    private var tableView: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView()
                Divider()
                filterView()

                Divider()
                tableHeader()
                Divider()
                    .padding(.bottom, 4)

                HStack {
                    ForEach(Array(store.columns.enumerated()), id: \.element.id) { index, item in
                        tableColumn(for: item, alignment: index == 0 ? .leading : .trailing,
                                    width: store.columnsWidth[index])
                    }
                }

                Spacer()
            }
        }
    }

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

    @ViewBuilder
    func tableHeader() -> some View {
        HStack {
            ForEach(store.headerItems) { header in
                VStack {
                    HStack {
                        VStack {
                            Text(header.title)
                                .font(.callout)
                                .fontWeight(.semibold)
                            if let subtitle = header.subtitle {
                                Text(subtitle)
                                    .font(.footnote)
                                    .fontWeight(.light)
                                    .italic()
                            }
                        }
                        if header.isDropdown {
                            Image(systemName: "chevron.down")
                                .font(.callout)
                        }
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(header.isDropdown ? Color.headerBackround : Color.whiteBackground)
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    func tableColumn(for column: TableColumn, alignment: HorizontalAlignment, width: CGFloat) -> some View {
        VStack(alignment: alignment) {
            ForEach(column.items) { item in
                Text(item.title)
                    .foregroundStyle(item.color)
                    .font(.callout)

                Divider()
            }
        }
        .frame(width: width)
    }
}

#Preview {
    GraphTableView(store: Store(initialState: GraphTableFeature.State()) {
        GraphTableFeature()
    })
}
