private func resetToAllItemsAndDisableRootNodes(
    allItems: IdentifiedArrayOf<AlternativeItemFeature.State>,
    isDisabled: Bool
) -> IdentifiedArrayOf<AlternativeItemFeature.State> {

    var result = allItems

    for index in result.indices {
        result[index].isDisabled = isDisabled
        result[index].isExpanded = false
    }

    return result
}
