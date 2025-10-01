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
            var children = items[index].identifiedArrayOfChildrens
            let childFound = markPreselected(in: &children, preselectedId: preselectedId)
            items[index].identifiedArrayOfChildrens = children

            if childFound {
                items[index].isExpanded = true   // 🔑 tu parent rozwija się, jeśli dziecko znalazło target
                found = true
            }
        }
    }

    return found
}
