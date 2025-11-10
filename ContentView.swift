struct TableColumn: Identifiable, Equatable, Sendable {
    let id = UUID()
    let items: [TableItem]
}


extension Array where Element == TableRow {
    func transposed() -> [TableColumn] {
        guard let firstRow = self.first else { return [] }
        let columnCount = firstRow.items.count

        return (0..<columnCount).map { columnIndex in
            let columnItems = self.map { $0.items[columnIndex] }
            return TableColumn(items: columnItems)
        }
    }
}
