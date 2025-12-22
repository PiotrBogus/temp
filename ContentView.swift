    func toggleDimensionOption(
        dimensionId: String,
        options: [GenieCommonDomain.Dimension.Option],
        in state: inout State
    ) -> Bool {
        guard let dimInd = state.dimensions.firstIndex(where: { $0.id == dimensionId }) else {
            return false
        }
        let current = state.dimensions[dimInd]

        let updated = options.reduce(current) { acc, option in
            // acc = updated dimension so far
            guard current.options.contains(option) else {
                return acc
            }
            let wasSelected = acc.selectedOptions.contains(where: { $0.id == option.id })
            return wasSelected ? acc.deselectOption(option) : acc.selectOption(option)
        }

        state.dimensions[dimInd] = updated

        return updated.selectedOptions != current.selectedOptions
    }
