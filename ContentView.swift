private func cloneTree(
    _ items: IdentifiedArrayOf<AlternativeItemFeature.State>
) -> IdentifiedArrayOf<AlternativeItemFeature.State> {

    IdentifiedArray(
        uniqueElements: items.map { item in
            var item = item
            item.isExpanded = false
            item.isSelected = false
            item.isDisabled = false
            item.children = cloneTree(
                IdentifiedArray(uniqueElements: item.children)
            ).elements
            return item
        }
    )
}
