struct MenuItemView: View {
    @Bindable var store: StoreOf<MenuItemFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {   // spacing 0 → zero „szpar”
            
            button

            if store.isPossibleToExpand,
               store.isExpanded {
                childrenView
            }
        }
        .background(Color.darkBlueBackground) // JEDYNE źródło tła
        .task { store.send(.onAppear) }
    }

    private var button: some View {
        Button {
            store.send(.didTapItem(id: store.id))
        } label: {
            HStack {
                Text(store.title)
                    .font(.title3)
                    .fontWeight(store.isExpanded || store.isSelected ? .semibold : .regular)
                    .foregroundColor(createTextColor(store.isSelected))

                Spacer()

                if store.isPossibleToExpand {
                    Image(systemName: store.isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(createRowBackgroundColor())
            )
        }
    }

    private var childrenView: some View {
        VStack(spacing: 0) {      // zero spacing = brak białych „cieni”
            ForEach(
                store.scope(state: \.identifiedArrayOfChildrens, action: \.children),
                id: \.state.id
            ) {
                MenuItemView(store: $0)
            }
            separatorView
        }
    }

    var separatorView: some View {
        Rectangle()
            .fill(Color.white)
            .frame(height: 1)
            .padding(.horizontal, 4)
    }

    private func createTextColor(_ isSelected: Bool) -> Color {
        isSelected ? .darkBlueBackground : .whiteText
    }

    private func createRowBackgroundColor() -> Color {
        store.isSelected ? .whiteBackground : .darkBlueBackground
    }
}
