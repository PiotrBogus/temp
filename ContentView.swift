private func cloneTree(
    _ items: IdentifiedArrayOf<AlternativeItemFeature.State>,
    isDisabled: Bool = false
) -> IdentifiedArrayOf<AlternativeItemFeature.State> {
    IdentifiedArray(
        uniqueElements: items.map { item in
            var item = item
            item.isExpanded = false
            item.isSelected = false
            item.isDisabled = isDisabled
            // rekurencyjnie kopiujemy children
            let clonedChildren = cloneTree(item.identifiedArrayOfChildrens, isDisabled: isDisabled)
            item.children = clonedChildren.elements
            item.identifiedArrayOfChildrens = clonedChildren
            return item
        }
    )
}
