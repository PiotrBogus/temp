public final class IntlMarketTrackerClient: Sendable {
    private let repository: IntMarketTrackerRepository

    public init(intMarketTrackerRepository: IntMarketTrackerRepository) {
        self.repository = intMarketTrackerRepository
    }

    // MARK: - Public API

    public func fetchIntMarketTracker(
        selectors: [SelectorParamEntity]
    ) async throws -> MarketTrackerKpiDataEntity {
        try await repository.fetchData(selectors: selectors)
    }

    public func convertEntityRowsAndHeaders(
        isLandscape: Bool,
        marketTrackerKpiEntity: MarketTrackerKpiDataEntity,
        selectedHeaders: [Int: Int]
    ) async -> ([KpiRowFeature<Int, Int>.State],
                IntlMarketTrackerHeaderFeature<Int>.State)? 
    {
        guard let layout = layout(for: marketTrackerKpiEntity, isLandscape: isLandscape),
              let labelColumnId = marketTrackerKpiEntity.columns.first?.id
        else { return nil }

        let initialVisibleColumnIds = visibleColumnIds(
            from: layout,
            selectedHeaders: selectedHeaders
        )

        let headerButtons = convertHeaders(
            from: layout,
            marketTrackerKpiEntity: marketTrackerKpiEntity,
            selectedHeaders: selectedHeaders
        )

        let headerIds = Array(headerButtons.ids)
        let headerStates = IdentifiedArray(
            uniqueElements: headerIds.compactMap { headerButtons[id: $0] }
        )

        let headerSegments = makeHeaderSegment(from: headerStates)

        var lineIndexes = extractSortedLineIndexes(from: headerSegments)
        lineIndexes.removeAll { $0 == headerIds.count }

        let columnGroupButtons = makeColumnGroupButtons(
            from: headerSegments,
            using: headerButtons
        )

        let headerState = IntlMarketTrackerHeaderFeature<Int>.State(
            buttons: headerButtons,
            columnGroupButtons: columnGroupButtons,
            segments: headerSegments,
            lineIndexes: lineIndexes
        )

        let rows = convertRows(
            from: marketTrackerKpiEntity,
            selectedColumnIds: initialVisibleColumnIds,
            labelColumnId: labelColumnId,
            lineIndexes: lineIndexes
        )

        return (rows, headerState)
    }

    public func headerItemSelected(
        isLandscape: Bool,
        buttonId: Int,
        optionId: String,
        marketTrackerKpiEntity: MarketTrackerKpiDataEntity?,
        selectors: [SelectorParamEntity]
    ) -> (isAssociatedIdSelected: Bool,
          updatedSelectors: [SelectorParamEntity],
          selectedHeaders: [Int: Int]) 
    {
        guard let kpiData = marketTrackerKpiEntity,
              let layout = layout(for: kpiData, isLandscape: isLandscape)
        else { return (false, selectors, [:]) }

        let columns = layout.visibleColumns
        guard columns.indices.contains(buttonId) else { return (false, selectors, [:]) }

        let column = columns[buttonId]

        if let result = applyAssociatedSelectorIfPossible(
            column: column,
            kpiData: kpiData,
            optionId: optionId,
            selectors: selectors
        ) {
            return result
        }

        if let headerId = Int(optionId) {
            return (false, selectors, [buttonId: headerId])
        }

        return (false, selectors, [:])
    }
}
