private func expandParentsForSelectedItems(
    in items: inout IdentifiedArrayOf<MenuItemFeature.State>
) -> Bool {
    var containsSelected = false

    for index in items.indices {
        // kopiujemy dzieci do zmiennych pomocniczych
        var children = items[index].identifiedArrayOfChildrens

        // rekurencyjnie sprawdzamy dzieci
        let childContainsSelected = expandParentsForSelectedItems(in: &children)

        // nadpisujemy zmodyfikowane dzieci w elemencie
        items[index].identifiedArrayOfChildrens = children

        // jeśli dziecko lub sam element jest selected → parent rozwiniety
        if items[index].isSelected || childContainsSelected {
            items[index].isExpanded = true
            containsSelected = true
        }
    }

    return containsSelected
}
