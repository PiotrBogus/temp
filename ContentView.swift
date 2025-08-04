struct TreeMenuItemView: View {
    @Binding var item: MenuItem
    var depth: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(item.children.isEmpty ? .body : .headline)
                    .bold(item.children.isEmpty == false)

                Spacer()

                if item.children.isEmpty == false {
                    Button {
                        item.isExpanded.toggle()
                    } label: {
                        Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.white)
                    }
                } else if item.isSelected {
                    Image(systemName: "checkmark")
                }
            }
            .padding(.horizontal, CGFloat(depth) * 16)
            .frame(height: 48)

            if item.isExpanded {
                ForEach($item.children) { $child in
                    TreeMenuItemView(item: $child, depth: depth + 1)
                }
            }
        }
    }
}
