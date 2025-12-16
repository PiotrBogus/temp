case .setSelectorOptions(let selector, let options):
    guard let selectorInd = state.selectors.firstIndex(where: { $0.id == selector.id })
    else {
        return .none
    }
    let current = state.selectors[selectorInd]
    
    // Validate options
    let validOptions = options.filter { option in
        current.options.contains(where: { $0.id == option.id })
    }
    
    guard !validOptions.isEmpty else {
        return .none
    }
    
    // Start with cleared selection, then apply each valid option
    var updated = current
    // First deselect all current options
    for option in current.selectedOptions {
        updated = updated.deselectOption(option)
    }
    // Then select all valid options
    for option in validOptions {
        updated = updated.selectOption(option)
    }
    
    state.selectors[selectorInd] = updated
    
    if updated.selectedOptions != current.selectedOptions {
        return .send(.delegate(.selectorsChangedTo(selector: updated)))
    }
    return .none
