private func resetTreeFromAllItems(
    _ allItems: IdentifiedArrayOf<AlternativeItemFeature.State>,
    isDisabled: Bool
) -> IdentifiedArrayOf<AlternativeItemFeature.State> {

    func reset(_ items: IdentifiedArrayOf<AlternativeItemFeature.State>)
    -> IdentifiedArrayOf<AlternativeItemFeature.State> {

        IdentifiedArray(
            uniqueElements: items.map { item in
                var item = item
                item.isExpanded = false
                item.isSelected = false
                item.isDisabled = isDisabled
                item.children = reset(item.children)
                return item
            }
        )
    }

    return reset(allItems)
}
