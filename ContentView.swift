@discardableResult
private func keepAncestorsAndCollapseOthers(
    expandedId: String,
    in items: inout IdentifiedArrayOf<MenuItemFeature.State>
) -> Bool {
    var found = false

    for index in items.indices {
        // Tworzymy lokalną kopię dzieci
        var children = items[index].identifiedArrayOfChildrens

        // Rekurencyjnie szukamy w dzieciach
        let childHasExpanded = keepAncestorsAndCollapseOthers(expandedId: expandedId, in: &children)

        // Nadpisujemy dzieci w elemencie
        items[index].identifiedArrayOfChildrens = children

        if items[index].id == expandedId {
            // To jest sam preselected element → zaznaczamy go
            items[index].isSelected = true
            // Nie zmieniamy isExpanded, bo parent nie jest tu
            found = true
        } else if childHasExpanded {
            // Jeśli któreś dziecko znalazło target → parent rozwinięty
            items[index].isExpanded = true
            found = true
        } else {
            // Jeśli w tym drzewie nie ma target → parent zamknięty
            items[index].isExpanded = false
        }
    }

    return found
}
