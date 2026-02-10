private func performFilter(
    with text: String,
    allItems: IdentifiedArrayOf<AlternativeItemFeature.State>
) -> Effect<Action> {
    return .run { send in
        // Wykonaj filtrowanie asynchronicznie
        let filteredItems: IdentifiedArrayOf<AlternativeItemFeature.State>
        
        if text.isEmpty {
            filteredItems = allItems
        } else {
            // Filtrowanie w tle
            filteredItems = await Task {
                return filterTree(
                    items: allItems,
                    searchText: text.lowercased()
                )
            }.value
        }
        
        await send(.didFilter(filteredItems))
    }
    .debounce(
        id: CancelID.filter,
        for: .milliseconds(300),
        scheduler: DispatchQueue.main
    )
}

// Zmień na funkcję statyczną lub globalną, żeby móc jej użyć w Task
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
        // Zostaw wszystkie dzieci gdy tytuł pasuje
        newItem.children = item.children
        newItem.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: item.children)
        newItem.isExpanded = true
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
