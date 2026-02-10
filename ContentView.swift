    @ViewBuilder
    private var searchBar: some View {
        RoundedRectangle(cornerSize: 24) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.body)
                    .foregroundColor(Color.text)

                TextField(
                    "Search Watchlist",
                    text: $store.searchText.sending(\.searchTextChanged)
                )
                .font(.body)
            }
        }
        .frame(height: 48)
        .background {
            Color.red
        }
        .padding(.horizontal, 26)
    }
