func toggleDimensionOption(
    dimensionId: String,
    options: [GenieCommonDomain.Dimension.Option],
    in state: inout State
) -> Bool {
    guard let dimInd = state.dimensions.firstIndex(where: { $0.id == dimensionId }) else {
        return false
    }

    let current = state.dimensions[dimInd]

    let updated: GenieCommonDomain.Dimension =
        current.allowsMultiselect
        ? handleMultiSelect(current: current, options: options)
        : handleSingleSelect(current: current, options: options)

    state.dimensions[dimInd] = updated
    return updated.selectedOptions != current.selectedOptions
}


private func handleMultiSelect(
    current: GenieCommonDomain.Dimension,
    options: [GenieCommonDomain.Dimension.Option]
) -> GenieCommonDomain.Dimension {
    options.reduce(current) { acc, option in
        guard current.options.contains(option) else {
            return acc
        }

        let isAlreadySelected = acc.selectedOptions.contains { $0.id == option.id }
        return isAlreadySelected ? acc : acc.selectOption(option)
    }
}


private func handleSingleSelect(
    current: GenieCommonDomain.Dimension,
    options: [GenieCommonDomain.Dimension.Option]
) -> GenieCommonDomain.Dimension {
    options.reduce(current) { acc, option in
        guard current.options.contains(option) else {
            return acc
        }

        let wasSelected = acc.selectedOptions.contains { $0.id == option.id }
        return wasSelected
            ? acc.deselectOption(option)
            : acc.selectOption(option)
    }
}
