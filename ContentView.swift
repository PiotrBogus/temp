private func filterTree(
    items: IdentifiedArrayOf<AlternativeItemFeature.State>,
    searchText: String
) -> IdentifiedArrayOf<AlternativeItemFeature.State> {
    
    var results: [AlternativeItemFeature.State] = []
    
    func collectMatching(_ item: AlternativeItemFeature.State) {
        // Sprawdź czy ten node pasuje
        if item.title.lowercased().contains(searchText) {
            var matchedItem = item
            matchedItem.isExpanded = false
            matchedItem.children = []
            matchedItem.identifiedArrayOfChildrens = []
            results.append(matchedItem)
        }
        
        // Rekurencyjnie sprawdź dzieci
        for child in item.children {
            collectMatching(child)
        }
    }
    
    for item in items {
        collectMatching(item)
    }
    
    return IdentifiedArrayOf(uniqueElements: results)
}
