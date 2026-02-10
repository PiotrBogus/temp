private func filterTree(
    items: IdentifiedArrayOf<AlternativeItemFeature.State>,
    searchText: String
) -> IdentifiedArrayOf<AlternativeItemFeature.State> {
    
    var results: [AlternativeItemFeature.State] = []
    
    func collectMatching(_ item: AlternativeItemFeature.State) {
        let titleMatches = item.title.lowercased().contains(searchText)
        
        if titleMatches {
            // Parent pasuje - dodaj go z wszystkimi dziećmi
            var matchedItem = item
            matchedItem.children = item.children
            matchedItem.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: item.children)
            matchedItem.isExpanded = true
            results.append(matchedItem)
        } else {
            // Parent NIE pasuje - sprawdź dzieci i dodaj je bezpośrednio
            for child in item.children {
                collectMatching(child)
            }
        }
    }
    
    for item in items {
        collectMatching(item)
    }
    
    return IdentifiedArrayOf(uniqueElements: results)
}
