func calculateColumnsWidth(columns: [TableColumn]) -> Effect<Action> {
    .run { send in
        // ✅ Zbieramy wszystkie tytuły z headera + elementów
        let titlesByColumns: [[String]] = columns.map { column in
            var titles = column.items.map(\.title)
            titles.append(column.header.title)
            if let subtitle = column.header.subtitle {
                titles.append(subtitle)
            }
            return titles
        }

        // ✅ Obliczamy wszystkie szerokości równolegle
        let baseWidths = await withTaskGroup(of: CGFloat.self) { group -> [CGFloat] in
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

        // ✅ Dodajemy padding i ewentualną ikonę dropdown
        let adjustedWidths = baseWidths.enumerated().map { index, width in
            let header = columns[index].header
            var adjusted = width + 16 // padding left + right
            if header.isDropdown {
                adjusted += 12 // szerokość ikony + spacing
            }
            return adjusted
        }

        await send(.didCalculateColumnsWidth(adjustedWidths))
    }
}
