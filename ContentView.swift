public struct IntlMarketTrackerClient: Sendable {
    public let fetchIntMarketTracker: @Sendable ([SelectorParamEntity]) async throws -> MarketTrackerKpiDataEntity
    public let convertEntityRowsAndHeaders: @Sendable (
        _ isLandscape: Bool,
        _ marketTrackerKpiEntity: MarketTrackerKpiDataEntity,
        _ selectedHeaders: [Int: Int]
    ) async -> ([KpiRowFeature<Int, Int>.State], IntlMarketTrackerHeaderFeature<Int>.State)?
    public let headerItemSelected: @Sendable (
        _ isLandscape: Bool,
        _ buttonId: Int,
        _ optionId: String,
        _ marketTrackerKpiEntity: MarketTrackerKpiDataEntity?,
        _ selectors: [SelectorParamEntity]
    ) -> (isAssociatedIdSelected: Bool, updatedSelectors: [SelectorParamEntity], selectedHeaders: [Int: Int])

    /// NEW: init który przyjmuje dowolne repozytorium implementujące protokół
    public init(intMarketTrackerRepository: IntMarketTrackerRepository) {
        self.fetchIntMarketTracker = { selectorsArray in
            try await intMarketTrackerRepository.fetchData(selectors: selectorsArray)
        }

        self.convertEntityRowsAndHeaders = { isLandscape, marketTrackerKpiEntity, selectedHeaders in
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

        self.headerItemSelected = { isLandscape, buttonId, optionId, marketTrackerKpiEntity, selectors in
            guard
                let kpiData = marketTrackerKpiEntity,
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
}


extension IntlMarketTrackerClient: DependencyKey {
    public static let liveValue = IntlMarketTrackerClient(
        intMarketTrackerRepository: IntMarketTrackerRepositoryLive()
    )

    public static let testValue = IntlMarketTrackerClient(
        intMarketTrackerRepository: IntMarketTrackerRepositoryMock()
    )

    public static let previewValue = testValue
}

public extension DependencyValues {
    var intlMarketTrackerClient: IntlMarketTrackerClient {
        get { self[IntlMarketTrackerClient.self] }
        set { self[IntlMarketTrackerClient.self] = newValue }
    }
}
