private func expandParentsIfChildSelected(
    in items: inout [MenuItemFeature.State]
) -> Bool {
    var containsSelected = false

    for index in items.indices {
        var children = items[index].children

        // Rekurencyjnie sprawdzamy dzieci
        let childContainsSelected = expandParentsIfChildSelected(in: &children)

        // Nadpisujemy zmodyfikowane dzieci
        items[index].children = children

        // Jeśli ten element jest selected albo któreś dziecko jest selected
        if items[index].isSelected || childContainsSelected {
            items[index].isExpanded = true
            containsSelected = true
        }
    }

    return containsSelected
}
