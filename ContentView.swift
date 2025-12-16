case .setSelectorOption(let selector, let option):
    guard let selectorInd = state.selectors.firstIndex(where: { $0.id == selector.id })
    else {
        return .none
    }
    let current = state.selectors[selectorInd]
    guard let newSelected = current.options.first(where: { $0 == option }) else {
        return .none
    }
    
    // Handle selection logic based on multiselect capability
    let updated: Selectors
    if current.allowsMultiselect {
        // For multiselect: toggle the option (add if not selected, remove if already selected)
        let wasSelected = current.selectedOptions.contains(where: { $0.id == option.id })
        if wasSelected {
            updated = current.deselectOption(newSelected)
        } else {
            updated = current.selectOption(newSelected)
        }
    } else {
        // For single-select: just select the option (replaces previous selection)
        updated = current.selectOption(newSelected)
    }
    
    state.selectors[selectorInd] = updated
    
    // Send delegate action only if selection actually changed
    if updated.selectedOptions != current.selectedOptions {
        return .send(.delegate(.selectorsChangedTo(selector: updated)))
    }
