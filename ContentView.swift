    @ViewBuilder
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.secondary)

            TextField(
                "Search items...",
                text: $store.searchText.sending(\.searchTextChanged)
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())

            if !store.searchText.isEmpty {
                Button {
//                    store.send(.clearSearch)
                }, label: {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.gray)
                }
                .foregroundColor(.accentColor)
            }
        }
    }
