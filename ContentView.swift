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
        newItem.isExpanded = true
        // Zostaw oryginalne dzieci jeśli tytuł pasuje
        return newItem
    }
    
    if !filteredChildren.isEmpty {
        var newItem = item
        newItem.children = filteredChildren
        newItem.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: filteredChildren)
        newItem.isExpanded = true
        return newItem
    }
    
    return nil
}

private func performFilter(
    with text: String,
    allItems: IdentifiedArrayOf<AlternativeItemFeature.State>
) -> Effect<Action> {
    return .run { send in
        // Wykonaj filtrowanie w tle
        let filtered = await Task.detached(priority: .userInitiated) {
            if text.isEmpty {
                return allItems
            } else {
                return self.filterTree(
                    items: allItems,
                    searchText: text.lowercased()
                )
            }
        }.value
        
        await send(.didFilter(filtered))
    }
    .debounce(
        id: CancelID.filter,
        for: .milliseconds(300),
        scheduler: DispatchQueue.main
    )
}
