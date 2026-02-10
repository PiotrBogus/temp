@ViewBuilder
private var searchBar: some View {
    HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
            .font(.body)
            .foregroundColor(Color.text)
        
        TextField(
            "Search Watchlist",
            text: $store.searchText.sending(\.searchTextChanged)
        )
        .font(.body)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        
        if !store.searchText.isEmpty {
            Button {
                store.send(.searchTextChanged(""))
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(height: 48)
    .background(
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(.systemGray6))
    )
    .padding(.horizontal, 26)
}
