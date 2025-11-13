struct TableItem: Identifiable, Equatable, Sendable {
    let id = UUID()
    let title: String
    let color: Color

    static let mock1: [TableItem] = [
        .init(title: "Novartis Brand", color: .black),
        .init(title: "Novartis Brand", color: .black),
        .init(title: "VeryLong Novartis Brand", color: .black),
        .init(title: "VeryLong VeryLong Novartis Brand", color: .black),
        .init(title: "Novartis Brand", color: .black)
    ]

    static let mock2: [TableItem] = [
        .init(title: "6,7%", color: .black),
        .init(title: "6,7%", color: .black),
        .init(title: "6,7%", color: .black),
        .init(title: "6,7%", color: .black),
        .init(title: "6,7%", color: .black)
    ]

    static let mock3: [TableItem] = [
        .init(title: "16ppt", color: .green),
        .init(title: "16ppt", color: .green),
        .init(title: "16ppt", color: .green),
        .init(title: "16ppt", color: .green),
        .init(title: "16ppt", color: .green)
    ]

    static let mock4: [TableItem] = [
        .init(title: "1,7ppt", color: .red),
        .init(title: "1,7ppt", color: .red),
        .init(title: "1,7ppt", color: .red),
        .init(title: "1,7ppt", color: .red),
        .init(title: "1,7ppt", color: .red)
    ]
}
