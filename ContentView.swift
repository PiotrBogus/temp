    @discardableResult
    private func keepAncestorsAndCollapseOthers(
        expandedId: String,
        in items: inout IdentifiedArrayOf<MenuItemFeature.State>
    ) -> Bool {
        var found = false
        for index in items.indices {
            if items[index].id == expandedId {
                found = true
                keepAncestorsAndCollapseOthers(
                    expandedId: expandedId,
                    in: &items[index].identifiedArrayOfChildrens
                )
            } else {
                let childHasExpanded = keepAncestorsAndCollapseOthers(
                    expandedId: expandedId,
                    in: &items[index].identifiedArrayOfChildrens
                )

                if childHasExpanded {
                    items[index].isExpanded = true
                    found = true
                } else {
                    items[index].isExpanded = false
                }
            }
        }

        return found
    }
