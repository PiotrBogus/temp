private func filterTree(
    items: IdentifiedArrayOf<AlternativeItemFeature.State>,
    searchText: String
) -> IdentifiedArrayOf<AlternativeItemFeature.State> {

    let filtered = items.compactMap { item in
        filterItem(item, searchText: searchText)
    }

    return IdentifiedArrayOf(uniqueElements: filtered)
}


private func filterItem(
    _ item: AlternativeItemFeature.State,
    searchText: String
) -> AlternativeItemFeature.State? {

    let titleMatches = item.title.lowercased().contains(searchText)

    let filteredChildren = item.children.compactMap {
        filterItem($0, searchText: searchText)
    }

    if titleMatches {
        var newItem = item
        newItem.children = item.children            // 🔹 pokaż całe subtree
        newItem.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: item.children)
        newItem.isExpanded = true                   // 🔹 auto-expand
        return newItem
    }

    if !filteredChildren.isEmpty {
        var newItem = item
        newItem.children = filteredChildren
        newItem.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: filteredChildren)
        newItem.isExpanded = true                   // 🔹 pokaż dzieci
        return newItem
    }

    return nil
}

case let .searchTextChanged(text):
    state.searchText = text

    if text.isEmpty {
        state.items = state.allItems
    } else {
        state.items = filterTree(
            items: state.allItems,
            searchText: text.lowercased()
        )
    }
    return .none
