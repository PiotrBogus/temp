private func collapseAndDisableAllItems(
    items: IdentifiedArrayOf<AlternativeItemFeature.State>,
    isDisabled: Bool
) -> IdentifiedArrayOf<AlternativeItemFeature.State> {
    
    let updatedItems = items.map { item in
        var updatedItem = item
        updatedItem.isExpanded = false
        updatedItem.isDisabled = isDisabled
        
        // Rekurencyjnie przetwórz wszystkie dzieci
        updatedItem.identifiedArrayOfChildrens = collapseAndDisableAllItems(
            items: item.identifiedArrayOfChildrens,
            isDisabled: isDisabled
        )
        
        // Zaktualizuj też children array
        updatedItem.children = Array(updatedItem.identifiedArrayOfChildrens)
        
        return updatedItem
    }
    
    return IdentifiedArrayOf(uniqueElements: updatedItems)
}
