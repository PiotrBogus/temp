private func expandAncestorsIfNeeded(in items: inout IdentifiedArrayOf<MenuItemFeature.State>) -> Bool {
    var containsSelected = false

    for index in items.indices {
        // sprawdzamy dzieci
        let childContainsSelected = expandAncestorsIfNeeded(in: &items[index].identifiedArrayOfChildrens)

        // jeśli samo jest selected lub któreś dziecko było selected → parent expand
        if items[index].isSelected || childContainsSelected {
            items[index].isExpanded = true
            containsSelected = true
        }
    }

    return containsSelected
}
