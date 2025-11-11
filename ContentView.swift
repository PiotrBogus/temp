import Foundation

struct TableColumn: Identifiable, Equatable, Sendable {
    let id = UUID()
    let header: TableHeader
    let items: [TableItem]

    static let mock: [TableColumn] = [
        .init(header: TableHeader.mock, items: TableItem.mock),
        .init(header: TableHeader.mock, items: TableItem.mock),
        .init(header: TableHeader.mock, items: TableItem.mock),
        .init(header: TableHeader.mock, items: TableItem.mock),
        .init(header: TableHeader.mock, items: TableItem.mock),
        .init(header: TableHeader.mock, items: TableItem.mock)
    ]
}
