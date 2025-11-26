//
//  IntlMarketTrackerClient.swift
//  KpiIntlMarketTracker
//
//  Created by Daniel Satin on 01.08.2025.
//

import ComposableArchitecture
import Dependencies
import DependenciesMacros
import GenieCommonPresentation
import KpiIntlMarketTrackerData
import KpiIntlMarketTrackerDomain
import GenieCommonDomain
import GenieApi

@DependencyClient
public struct IntlMarketTrackerClient: Sendable {
    var fetchIntMarketTracker: @Sendable (_ selectors: [SelectorParamEntity]) async throws -> MarketTrackerKpiDataEntity

    var convertEntityRowsAndHeaders: @Sendable (_ isLandscape: Bool,
                                                _ marketTrackerKpiEntity: MarketTrackerKpiDataEntity,
                                                _ selectedHeader: [Int: Int]) async -> ([KpiRowFeature<Int, Int>.State], IntlMarketTrackerHeaderFeature<Int>.State)?
    
    var headerItemSelected: @Sendable (
        _ isLandscape: Bool,
        _ buttonId: Int,
        _ optionId: String,
        _ marketTrackerKpiEntity: MarketTrackerKpiDataEntity?,
        _ selectors: [SelectorParamEntity]
    ) -> (
        isAssociatedIdSelected: Bool,
        updatedSelectors: [SelectorParamEntity],
        selectedHeaders: [Int: Int]
    ) = { _, _, _, _, _ in (false, [], [:]) }
}

extension IntlMarketTrackerClient: DependencyKey {
    public static let liveValue: IntlMarketTrackerClient = {
        @Dependency(\.intMarketTrackerRepository) var intMarketTrackerRepository

        return IntlMarketTrackerClient(
            fetchIntMarketTracker: { selectorsArray in
                try await intMarketTrackerRepository.fetchData(selectors: selectorsArray)
            },
            convertEntityRowsAndHeaders: { isLandscape, marketTrackerKpiEntity, selectedHeaders in
                guard let layout = layout(for: marketTrackerKpiEntity, isLandscape: isLandscape),
                      let labelColumnId = marketTrackerKpiEntity.columns.first?.id
                else {
                    return nil
                }

                let initialVisibleColumnIds = visibleColumnIds(from: layout, selectedHeaders: selectedHeaders)
                let headerButtons = convertHeaders(from: layout, marketTrackerKpiEntity: marketTrackerKpiEntity, selectedHeaders: selectedHeaders)

                let headerIds = Array(headerButtons.ids)
                let headerStates = IdentifiedArray(uniqueElements: headerIds.compactMap { headerButtons[id: $0] })
                let headerSegments = makeHeaderSegment(from: headerStates)
                
                var lineIndexes: [Int] = extractSortedLineIndexes(from: headerSegments)
                // Remove line if it is after last column
                lineIndexes.removeAll { $0 == headerIds.count }

                let columnGroupButtons = makeColumnGroupButtons(from: headerSegments, using: headerButtons)
                let headerState = IntlMarketTrackerHeaderFeature<Int>.State(buttons: headerButtons,
                                                                            columnGroupButtons: columnGroupButtons,
                                                                            segments: headerSegments,
                                                                            lineIndexes: lineIndexes)
                let rows = convertRows(from: marketTrackerKpiEntity,
                                       selectedColumnIds: initialVisibleColumnIds,
                                       labelColumnId: labelColumnId,
                                       lineIndexes: lineIndexes)
                return (rows, headerState)
            },
            headerItemSelected: { isLandscape, buttonId, optionId, marketTrackerKpiEntity, selectors in
                guard let kpiData = marketTrackerKpiEntity,
                      let layout = IntlMarketTrackerClient.layout(for: kpiData, isLandscape: isLandscape)
                else {
                    return (false, selectors, [:]) // no change
                }

                let columns = layout.visibleColumns
                guard columns.indices.contains(buttonId) else {
                    return (false, selectors, [:]) // no change
                }

                let column = columns[buttonId]

                if let result = applyAssociatedSelectorIfPossible(
                    column: column,
                    kpiData: kpiData,
                    optionId: optionId,
                    selectors: selectors
                ) {
                    // column have associatedId -> fetch data with updatedSelectors
                    return result
                }

                if let headerId = Int(optionId) {
                    // column have multiple columnId -> update table with selected columnId
                    return (false, selectors, [buttonId: headerId])
                }

                return (false, selectors, [:]) // no change
            }
        )
    }()

    public static let testValue: Self = .init(
        fetchIntMarketTracker: { selectors in  
            MarketTrackerKpiDataEntity(
                title: "",
                selectors: [],
                columns: [],
                layouts: [],
                dataFormats: [], // TODO: Delete !!!!!!
                rows: []
            )
        },
        convertEntityRowsAndHeaders: { _, _, _  in
            ([], IntlMarketTrackerHeaderFeature<Int>.State())
        },
        headerItemSelected: { _, _, _, _, _ in
            (false, [], [:])
        }
    )

    public static let previewValue: Self = testValue
}
