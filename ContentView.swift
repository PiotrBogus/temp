private func markPreselected(
    in items: inout IdentifiedArrayOf<MenuItemFeature.State>,
    preselectedId: String
) -> Bool {
    var found = false

    for index in items.indices {
        if items[index].id == preselectedId {
            items[index].isSelected = true
            found = true
        } else {
            let childFound = markPreselected(
                in: &items[index].identifiedArrayOfChildrens,
                preselectedId: preselectedId
            )
            if childFound {
                // jeśli dziecko zawiera preselected → parent się rozwija
                items[index].isExpanded = true
                found = true
            }
        }
    }

    return found
}
