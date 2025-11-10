struct TableItem: Identifiable, Equatable, Sendable {
    let id = UUID()
    let title: String
    let color: Color

    static let mock: [TableItem] = [
        .init(title: "Novartis Brand", color: .black),
        .init(title: "6,7%", color: .black),
        .init(title: "16ppt", color: .green),
        .init(title: "1,7ppt", color: .red),
    ]
}

struct TableRow: Identifiable, Equatable, Sendable {
    let id = UUID()
    let items: [TableItem]

    static let mock: [TableRow] = [
        .init(items: TableItem.mock),
        .init(items: TableItem.mock),
        .init(items: TableItem.mock),
        .init(items: TableItem.mock),
        .init(items: TableItem.mock),
        .init(items: TableItem.mock)
    ]
}
