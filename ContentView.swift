case .setSelectorOptions(let selector, let options):
    guard let selectorInd = state.selectors.firstIndex(where: { $0.id == selector.id })
    else {
        return .none
    }
    let current = state.selectors[selectorInd]
    
    // Validate that all options exist in the selector's available options
    let validOptions = options.filter { option in
        current.options.contains(where: { $0.id == option.id })
    }
    
    guard !validOptions.isEmpty else {
        return .none
    }
    
    // Create a new selector with the provided options as selected
    var updated = current
    updated.selectedOptions = validOptions
    
    state.selectors[selectorInd] = updated
    
    // Send delegate action only if selection actually changed
    if updated.selectedOptions != current.selectedOptions {
        return .send(.delegate(.selectorsChangedTo(selector: updated)))
    }
    return .none
