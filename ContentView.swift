import ComposableArchitecture
import GenieCommonPresentation
import SwiftUI

// PreferenceKey mierzący maksymalną wysokość treści (headerów i komórek)
private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

public struct GraphTableView: View {
    @Bindable var store: StoreOf<GraphTableFeature>

    // dynamiczna maksymalna wysokość (mierzona)
    @State private var maxCellHeight: CGFloat = 44
    @State private var availableWidth: CGFloat = 0

    private struct Constants {
        static let defaultColumnWidth: CGFloat = 80
        static let headerInnerPadding: CGFloat = 4
        static let horizontalSpacing: CGFloat = 8
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
                    mainTable(availableWidth: geo.size.width)
                }
            }
            .onAppear { availableWidth = geo.size.width }
        }
        .background(Color.whiteBackground)
        .task { store.send(.onAppear) }
        // gdy preferenceKey się zmieni, ustawiamy wysokość (bez dodawania "magicznych" offsetów)
        .onPreferenceChange(ContentHeightKey.self) { newH in
            if newH > 0 && newH != maxCellHeight {
                maxCellHeight = newH
            }
        }
    }

    private func mainTable(availableWidth: CGFloat) -> some View {
        // obliczenie szer. całkowitej na podstawie store.columnsWidth (tej, którą liczy feature)
        let computedWidth = store.columnsWidth.reduce(0, +) + CGFloat(max(0, store.columns.count - 1)) * Constants.horizontalSpacing
        let needsHorizontalScroll = computedWidth > availableWidth

        return Group {
            if needsHorizontalScroll {
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

    // główna treść tabeli
    @ViewBuilder
    private func tableContent(evenly: Bool) -> some View {
        VStack(spacing: .zero) {
            titleBar()
            Divider()
            filterBar()

            // header section
            VStack(spacing: .zero) {
                Divider() // górny
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
                .frame(height: maxCellHeight) // wysokość wyrównana do zmierzonej
                Divider() // dolny
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

    // title bar
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

    // filter bar
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

    // header cell — tło tylko wokół treści z paddingiem 4
    @ViewBuilder
    private func headerCell(_ header: TableHeader, width: CGFloat? = nil, alignment: HorizontalAlignment) -> some View {
        // HStack kontroluje alignment wizualny; tło jest tylko za zawartością (padding)
        HStack {
            if alignment == .trailing { Spacer(minLength: 0) }

            HStack(spacing: 4) {
                VStack(alignment: alignment, spacing: 2) {
                    Text(header.title)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
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
            .padding(4) // <-- tło będzie o 4 px większe z każdej strony
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(header.isDropdown ? Color.headerBackround : Color.whiteBackground)
            )
            // Mierzymy wysokość treści (bez dodatkowych „+8”), żeby preference dawało realną wysokość
            .background(GeometryReader { proxy in
                Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
            })

            if alignment == .leading { Spacer(minLength: 0) }
        }
        .frame(width: width, height: maxCellHeight, alignment: alignment == .leading ? .leading : .trailing)
    }

    // kolumna danych; każdy wiersz mierzy swoją treść wysokości i ustawia tę wysokość
    @ViewBuilder
    private func columnView(items: [TableItem], alignment: HorizontalAlignment, width: CGFloat? = nil) -> some View {
        VStack(alignment: alignment, spacing: .zero) {
            ForEach(items.indices, id: \.self) { idx in
                let item = items[idx]
                HStack {
                    if alignment == .trailing { Spacer(minLength: 0) }

                    Text(item.title)
                        .font(.footnote)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
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
