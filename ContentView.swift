private func filterTree(
    items: IdentifiedArrayOf<AlternativeItemFeature.State>,
    searchText: String
) -> IdentifiedArrayOf<AlternativeItemFeature.State> {

    var results: [AlternativeItemFeature.State] = []

    func collectMatching(_ item: AlternativeItemFeature.State) {
        let titleMatches = item.title.lowercased().contains(searchText)

        if titleMatches {
            // Zachowaj oryginalny item z jego stanem
            var matchedItem = item
            // Zachowaj wszystkie dzieci z ich oryginalnym stanem
            matchedItem.children = item.children
            matchedItem.identifiedArrayOfChildrens = item.identifiedArrayOfChildrens
            matchedItem.isExpanded = true
            results.append(matchedItem)
        } else {
            // Parent nie pasuje - sprawdź dzieci
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
