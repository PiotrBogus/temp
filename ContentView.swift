struct IndentationView: View {

    let level: Int
    let isExpandable: Bool
    let isExpanded: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {

            // pionowe linie
            ForEach(0..<level, id: \.self) { _ in
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
            }

            // ikonka
            if isExpandable {
                Image(systemName: isExpanded ? "minus.circle" : "plus.circle")
                    .foregroundColor(.gray)
            } else {
                Circle()
                    .fill(isSelected ? Color.red : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
        .frame(minWidth: 20, alignment: .leading)
    }
}
