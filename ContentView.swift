func calculateColumnsWidth(columns: [TableColumn]) -> Effect<Action> {
    .run { send in
        // ✅ Każda kolumna = header.title + header.subtitle + items.title
        let titlesByColumns: [[String]] = columns.map { column in
            var titles = column.items.map(\.title)
            titles.append(column.header.title)
            if let subtitle = column.header.subtitle {
                titles.append(subtitle)
            }
            return titles
        }

        // ✅ Obliczamy równolegle maksymalne szerokości kolumn
        let widths = await withTaskGroup(of: CGFloat.self) { group -> [CGFloat] in
            for titles in titlesByColumns {
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
