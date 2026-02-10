private func collapseAndDisableAllItems(
    in items: inout IdentifiedArrayOf<AlternativeItemFeature.State>,
    isDisabled: Bool
) {
    for index in items.indices {
        items[index].isExpanded = false
        items[index].isDisabled = isDisabled
        
        // Rekurencyjnie przetwórz wszystkie dzieci
        var children = items[index].identifiedArrayOfChildrens
        collapseAndDisableAllItems(in: &children, isDisabled: isDisabled)
        items[index].identifiedArrayOfChildrens = children
        
        // Zaktualizuj też children array
        items[index].children = Array(children)
    }
}


case let .toggleChanged(isOn):
    state.isOn = isOn
    state.searchText = ""
    
    // Zwinięcie i ustawienie disabled na WSZYSTKICH elementach (allItems i items)
    collapseAndDisableAllItems(in: &state.allItems, isDisabled: !isOn)
    
    // Przywróć items z zaktualizowanego allItems
    state.items = state.allItems
    
    return .none
