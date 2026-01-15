//
//  IntlMarketTrackerChartContainerFeature.swift
//  KpiIntlMarketTracker
//
//  Created by Daniel Satin on 09.11.2025.
//

import ComposableArchitecture
import GenieCommonPresentation
import GenieCommonDomain

@Reducer
public struct IntlMarketTrackerChartContainerFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        var mode: Mode = .chart
        var chart: ChartComponentFeature.State
        var table: ChartTableComponentFeature.State

        public init(
            selectors: [SelectorParamEntity]
        ) {
            self.chart = createDefaultChartComponent(selectors: selectors)
            self.table = ChartTableComponentFeature.State(selectors: selectors)
        }
    }

    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case chart(ChartComponentFeature.Action)
        case closeButtonTapped
        case onAppear
        case table(ChartTableComponentFeature.Action)
    }

    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.chart, action: \.chart) {
            ChartComponentFeature()
        }
        .dependency(\.chartComponentFeatureClient, ChartComponentFeatureClient(
            fetchChartData: { selectors in
                @Dependency(\.intlMarketTrackerChartComponentFeatureClient) var client
                return try await client.fetchChartData(selectors)
            }))

        Scope(state: \.table, action: \.table) {
            ChartTableComponentFeature()
        }

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .chart(.delegate(.selectorsToSyncChanged(selectorsToSync))):
                return reduce(into: &state, action: .table(.selectorsToSyncChanged(selectorsToSync)))

            case .chart:
                return .none

            case .closeButtonTapped:
                return .run { _ in await dismiss() }

            case .onAppear:
                return .none

            case let .table(.delegate(.selectorsToSyncChanged(selectorsToSync))):
                return reduce(into: &state, action: .chart(.selectorsToSyncChanged(selectorsToSync)))

            case .table:
                return .none
            }
        }
    }
}

extension IntlMarketTrackerChartContainerFeature.State {
    enum Mode: String, Equatable, Hashable, Sendable, Identifiable, CaseIterable {
        case chart
        case table
        public var id: Self { self }
    }
}

//TODO: CHARTS - Refactor this not to be here freely
func createDefaultChartComponent(selectors: [SelectorParamEntity]) -> ChartComponentFeature.State {
    let chartContainerState = ChartTableToolbarFeatureWithChartData.State()

    let chartState = ChartFeature<String>.State(
        id: "intl-market-tracker-chart",
        chartData: [],
        legendItems: [],
        formatterConfig: ChartFormatterConfig.createMock()
    )

    return ChartComponentFeature.State(
        chart: chartState,
        chartContainer: chartContainerState,
        chartItems: [],
        allPossibleLegends: [],
        inputSelectors: selectors
    )
}




import ComposableArchitecture
import Foundation
import GenieCommonDomain

@Reducer
public struct ChartTableComponentFeature: Sendable {
    public typealias RowID = Int
    public typealias ValueID = Int
    public typealias HeaderID = Int

    public typealias TableFeature = KpiTableFeature<RowID, ValueID>
    public typealias HeaderFeature = IntlMarketTrackerHeaderFeature<HeaderID>

    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        @Presents var error: ErrorFeature.State?

        @Shared(.deviceOrientation) var deviceOrientation: DeviceOrientation = .unknown
        @Shared var isLoading: Bool
        @Shared var headerFilterOptions: IdentifiedArrayOf<OptionPickerRowFeature<Int>.State>
        @Shared var selectedSelectors: [Int: String] /// [selectorId : selectedFilterId]

        var table: TableFeature.State?
        var header: HeaderFeature.State?
        var headerSelectorPanel: ChartTableFilterPanelFeature.State?

        var title: String = "INTL Market Tracker"
        var isBookmarkExists: Bool = false

        var dataFormats: [DataFormatEntity]?
        var marketTrackerKpiData: MarketTrackerKpiDataEntity?
        var inputSelectors: [SelectorParamEntity] = []
        var selectedHeaders: [Int: Int] = [:] /// [selected buttonIndex : columnId]

        var chartFilterSelectors: [Selectors] = []
        var selectedColumnsSelectors: [Int] = []

        var sortableColumns: [ColumnDefinition] = []
        var sortingCriteria: SortingCriteria = .init(order: .descending)

        var navigationTitle: String {
            "INTL Market Tracker"
        }

        let pageIdParameter: String = "page_id"

        public init(selectors: [SelectorParamEntity]) {
            self._isLoading = Shared(value: false)
            self._headerFilterOptions = Shared(value: [])
            self._selectedSelectors = Shared(value: [:])
            self.inputSelectors = selectors
        }
    }

    public enum Action: Sendable {
        case marketTrackerDataFetched(MarketTrackerKpiDataEntity, [DataFormatEntity])
        case dataMapped([KpiRowFeature<RowID, ValueID>.State], HeaderFeature.State)
        case delegate(Delegate)
        case deviceOrientationChanged
        case error(ErrorFeature.Action)
        case header(HeaderFeature.Action)
        case headerSelectorPanel(ChartTableFilterPanelFeature.Action)
        case onError(Error)
        case onFirstAppear
        case selectorsChanged(IdentifiedArrayOf<OptionPickerRowFeature<Int>.State>)
        case selectorsToSyncChanged([Selectors])
        case table(TableFeature.Action)
    }

    @Dependency(\.chartTableComponentClient) private var chartTableComponentClient
    @Dependency(\.logger) private var logger
    @Dependency(\.kpiDataMapper) private var kpiDataMapper
    @Dependency(\.kpiRowMapper) private var kpiRowMapper
    @Dependency(\.chartOutputMapper) var chartOutputMapper
    @Dependency(\.columnWidthHelper) private var columnWidthHelper

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .marketTrackerDataFetched(marketTrackerKpiData, dataFormats):
                state.marketTrackerKpiData = marketTrackerKpiData
                state.dataFormats = dataFormats
                
                /// InputSelectors are initialized
                if state.inputSelectors.count < 2 {
                    state.inputSelectors.append(contentsOf: marketTrackerKpiData.selectors
                        .filter { $0.name != state.pageIdParameter } // Exclude page_id
                        .map { SelectorParamEntity(selectorName: $0.name, selectorValue: $0.defaultValue) }
                    )
                }
                
                if let columnSelect = marketTrackerKpiData.columnSelector, !columnSelect.isEmpty {
                    state.selectedColumnsSelectors = columnSelect.first?.defaultColumnsIds ?? []
                }

                /// Update picker options with labels
                state.$headerFilterOptions.withLock {
                    $0 = kpiDataMapper.updateHeaderFilterOptions(
                        kpiData: marketTrackerKpiData,
                        isLandscape: state.deviceOrientation.isLandscape,
                        userSelectedFilters: state.selectedSelectors
                    )
                }

                guard let (rows, headerState) = convertDataToStates(
                    state: &state
                ) else {
                    return .none
                }

                return .run { send in
                    let (updatedRows, updatedheaderState) = await calculateWidth(rows: rows, headerState: headerState)
                    await send(.dataMapped(updatedRows, updatedheaderState))
                }

            case let .dataMapped(rowStates, headerState):
                state.$isLoading.withLock { $0 = false }
                state.table = TableFeature.State(rows: .init(uniqueElements: rowStates))
                state.header = headerState
                
                guard let kpiData = state.marketTrackerKpiData,
                      let layout = kpiDataMapper.currentLayout(for: kpiData, isLandscape: state.deviceOrientation.isLandscape)
                else {
                    return .none
                }

                let filterSelectors = kpiDataMapper.convertSelectorsToDimensions(
                    selectors: state.marketTrackerKpiData?.selectors,
                    selectorsRowContent: layout.selectorsRowContent,
                    inputSelectors: state.inputSelectors
                ) ?? []


                var brandSelectors: [Selectors] = []
                if let colSelector = state.marketTrackerKpiData?.columnSelector?.first,
                   colSelector.options.count > 0,
                   let columns = state.marketTrackerKpiData?.tables.main.columns {
                    let colFilters = kpiDataMapper.convertColumnSelectorToFilters(
                        columnSelector: colSelector,
                        columns: columns,
                        selectedColumnIds: state.selectedColumnsSelectors
                    )
                    brandSelectors.append(contentsOf: colFilters)
                }

                state.headerSelectorPanel = ChartTableFilterPanelFeature.State(
                    selectors: filterSelectors,
                    brandSelectors: brandSelectors
                )
                return .none

            case .deviceOrientationChanged:
                guard let (rows, headerState) = convertDataToStates(
                    state: &state
                ) else {
                    return .none
                }
                return .run { send in
                    let (updatedRows, updatedheaderState) = await calculateWidth(rows: rows, headerState: headerState)
                    await send(.dataMapped(updatedRows, updatedheaderState))
                }

            case let .header(.buttons(.element(id: buttonID, action: .delegate(.tapped(optionId))))),
                let .header(.columnGroupButtons(.element(id: _, action: .delegate(.tapped(buttonID, optionId))))):
                logger.debug("Tapped header button with ID: \(buttonID) \(optionId)")
                let (isAssociatedIdSelected, updatedSelectors, selectedHeaders) = kpiDataMapper.headerItemSelected(
                    isLandscape: state.deviceOrientation.isLandscape,
                    buttonId: buttonID, optionId: optionId,
                    marketTrackerKpiEntity: state.marketTrackerKpiData,
                    selectors: state.inputSelectors
                )
                if isAssociatedIdSelected {
                    /// AssociatedIdSelected -> make a new api call
                    state.inputSelectors = updatedSelectors
                    return fetchData(
                        state: &state,
                        selectors: updatedSelectors
                    )
                } else {
                    /// ColumnId is selected from header -> update table
                    state.selectedHeaders.merge(selectedHeaders) { _, new in new }
                    guard let (rows, headerState) = convertDataToStates(
                        state: &state
                    ) else {
                        return .none
                    }
                    return .run { send in
                        let (updatedRows, updatedheaderState) = await calculateWidth(rows: rows, headerState: headerState)
                        await send(.dataMapped(updatedRows, updatedheaderState))
                    }
                }
            case let .headerSelectorPanel(.delegate(.selectorsChangedTo(selectors))):
                let didChange = handleSelectorsChanged(
                    newSelectors: selectors,
                    state: &state,
                    originalSelectors: state.marketTrackerKpiData?.selectors
                )

                guard didChange else {
                    return .none
                }
                return .merge(
                    fetchData(state: &state, selectors: state.inputSelectors),
                    .run { send in
                        await send(.delegate(.selectorsToSyncChanged(selectors)))
                    }
                )

            case let .headerSelectorPanel(.delegate(.brandSelectorsChangedTo(selectors))):
                print(selectors)
                state.selectedColumnsSelectors = []
                if let selectedOptionArr = selectors.first?.selectedOptions {
                    selectedOptionArr.forEach { opt in
                        if let optionId = Int(opt.id) {
                            state.selectedColumnsSelectors.append(optionId)
                        }
                    }
                }
                guard let (rows, headerState) = convertDataToStates(
                    state: &state
                ) else {
                    return .none
                }
                return .run { send in
                    let (updatedRows, updatedheaderState) = await calculateWidth(rows: rows, headerState: headerState)
                    await send(.dataMapped(updatedRows, updatedheaderState))
                }

            case .error(.delegate(.retry)):
                state.error = nil
                return fetchData(
                    state: &state,
                    selectors: state.inputSelectors
                )

            case .error:
                return .none

            case let .onError(error):
                state.$isLoading.withLock { $0 = false }
                state.error = .build(from: error)
                return .none

            case .onFirstAppear:
                guard state.marketTrackerKpiData == nil else {
                    if !state.chartFilterSelectors.isEmpty {
                        let didChange = handleSelectorsChanged(
                            newSelectors: state.chartFilterSelectors,
                            state: &state,
                            originalSelectors: state.marketTrackerKpiData?.selectors
                        )

                        if didChange {
                            return fetchData(state: &state, selectors: state.inputSelectors)
                        }
                    }
                    return .none
                }

                return .merge(
                    fetchData(state: &state, selectors: state.inputSelectors),
                    observeDeviceOrientation(state.$deviceOrientation),
                    observeHeaderFilterOptions(state.$headerFilterOptions)
                )

            case let .selectorsChanged(optionPickerRows):
                logger.debug("Refreshing data due to changed selectors. Selectors: \(optionPickerRows)")
                updateStateByChangedSelectorsFetchData(
                    state: &state,
                    updatedSelectedFilters: optionPickerRows
                )

                return fetchData(
                    state: &state,
                    selectors: state.inputSelectors
                )

            case let .selectorsToSyncChanged(selectorsToSync):
                state.chartFilterSelectors = selectorsToSync
                logger.debug("Refreshing data due to changed selectors. Selectors: \(selectorsToSync)")
                return .none

            case .table(.delegate(.onRefresh)):
                logger.debug("Pull to refresh invoked")
                return fetchData(
                    state: &state,
                    selectors: state.inputSelectors
                )

            case .table(.rows(.element(id: let rowID, action: .delegate(.rowTapped)))):
                logger.debug("Tapped row button with ID: \(rowID)")
                return .none

            case .table(.rows(.element(id: let rowID, action: .delegate(.chartButtonTapped)))):
                logger.debug("Tapped chart button with ID: \(rowID)")
                return .send(.delegate(.chartButtonTapped(rowID)))

            case .table(
                .rows(
                    .element(
                        id: let rowID,
                        action: .values(.element(id: let valueID, action: .delegate(.tapped)))
                    )
                )
            ):
                logger.debug("Tapped value button with ID: \(valueID) in row with ID: \(rowID)")
                return .none

            case .delegate, .header, .headerSelectorPanel, .table:
                return .none
            }
        }
        .ifLet(\.table, action: \.table) { TableFeature() }
        .ifLet(\.header, action: \.header) { HeaderFeature() }
        .ifLet(\.headerSelectorPanel, action: \.headerSelectorPanel) { ChartTableFilterPanelFeature() }
        .ifLet(\.error, action: \.error) { ErrorFeature() }
    }
}

// MARK: - Effects

extension ChartTableComponentFeature {
    private func observeDeviceOrientation(_ shared: Shared<DeviceOrientation>) -> Effect<Action> {
        .run { send in
            for await _ in shared.publisher.dropFirst().values {
                await send(.deviceOrientationChanged)
            }
        }
        .cancellable(id: CancelID.deviceOrientationObserver, cancelInFlight: true)
    }

    private func observeHeaderFilterOptions(
        _ shared: Shared<IdentifiedArrayOf<OptionPickerRowFeature<Int>.State>>
    ) -> Effect<Action> {
        .run { send in
            for await options in shared.publisher.dropFirst().removeDuplicates().values {
                await send(.selectorsChanged(options))
            }
        }
        .cancellable(id: CancelID.headerFilterOptionsObserver, cancelInFlight: true)
    }

    private func fetchData(
        state: inout State,
        selectors: [SelectorParamEntity]
    ) -> Effect<Action> {
        state.$isLoading.withLock { $0 = true }
        state.selectedHeaders = [:]

        return .run { send in
            async let marketTrackerKpiData = try await chartTableComponentClient.fetchTableData(selectors: selectors)
            async let fetchedDataFormats = try chartTableComponentClient.fetchDataFormats()
            let _ = try await (fetchedDataFormats, marketTrackerKpiData)
            try await send(.marketTrackerDataFetched(marketTrackerKpiData, fetchedDataFormats))
        } catch: { error, send in
            await send(.onError(error))
        }
    }
    
    private func calculateWidth(
        rows: [KpiRowFeature<Int, Int>.State],
        headerState: HeaderFeature.State
    ) async -> ([KpiRowFeature<RowID, ValueID>.State], HeaderFeature.State) {
        var rowsState = rows
        var headersState = headerState
        
        let calculations = await columnWidthHelper.calculateWidths(rows: rows, headerButtons: headerState.buttons)
    
        rowsState = rowsState.map { row in
            var row = row
            row.setColumnWidths(columnWidths: calculations)
            return row
        }
        
        headersState.setColumnWidths(columnWidths: calculations)
        
        return (rowsState, headersState)
    }
    
    func handleSelectorsChanged(
        newSelectors: [FilterWithOptions],
        state: inout State,
        originalSelectors: [SelectorEntity]?
    ) -> Bool {
        guard let originalSelectors, !originalSelectors.isEmpty else { return false }

        var didChange = false

        for newSelector in newSelectors {
            // Match FilterWithOptions -> SelectorEntity (id types might differ)
            guard let original = originalSelectors.first(where: { String(describing: $0.id) == newSelector.id }) else {
                continue
            }

            let name = original.name
            let newValue = newSelector.selectedOptions.first?.id ?? ""

            // Update existing input selector (match by selectorName)
            if let idx = state.inputSelectors.firstIndex(where: { $0.selectorName == name }) {
                let oldValue = state.inputSelectors[idx].selectorValue ?? ""
                if oldValue != newValue {
                    didChange = true
                    state.inputSelectors[idx].selectorValue = newValue
                }
            } else {
                // If it's not there yet, add it (counts as a change if you want to refetch)
                state.inputSelectors.append(
                    SelectorParamEntity(selectorName: name, selectorValue: newValue)
                )
                didChange = true
            }
        }

        return didChange
    }



    private func updateStateByChangedSelectorsFetchData(
        state: inout State,
        updatedSelectedFilters: IdentifiedArrayOf<OptionPickerRowFeature<Int>.State>
    ) {
        state.$headerFilterOptions.withLock { $0 = updatedSelectedFilters }
        /// Update inputSelectors according to headerFilterOptions and kpi metadata
        state.inputSelectors = kpiDataMapper.updateInputSelectors(
            existingSelectors: state.inputSelectors,
            headerFilterOptions: state.headerFilterOptions,
            kpiData: state.marketTrackerKpiData,
            selectedSelectors: state.selectedSelectors
        )
    }

    private func convertDataToStates(
        state: inout State,
    ) -> ([KpiRowFeature<RowID, ValueID>.State], HeaderFeature.State)? {
        guard let kpiData = state.marketTrackerKpiData,
              let dataFormats = state.dataFormats,
              let layout = kpiDataMapper.currentLayout(for: kpiData, isLandscape: state.deviceOrientation.isLandscape),
              let firstColumnId = kpiData.tables.main.columns.first?.id
        else {
            return .none
        }

        let (headerButtons, columnGroupButtons, headerSegments, lineIndexes, initialVisibleColumnIds) =
        kpiDataMapper.convertDataToStatesAndHeaderElements(currentLayout: layout,
                                                           marketTrackerKpiData: kpiData,
                                                           selectedHeaders: state.selectedHeaders,
                                                           selectedColumnsSelectors: state.selectedColumnsSelectors)

        var sortableColumns: [ColumnDefinition] = []
        for column in kpiData.tables.main.columns {
            if initialVisibleColumnIds.contains(column.id), column.sortable {
                let definition = ColumnDefinition(id: column.id, title: column.title)
                sortableColumns.append(definition)
            }
        }
        state.sortableColumns = sortableColumns


        let headerState = IntlMarketTrackerHeaderFeature<Int>.State(buttons: headerButtons,
                                                                    columnGroupButtons: columnGroupButtons,
                                                                    segments: headerSegments,
                                                                    lineIndexes: lineIndexes)
        let rows = kpiRowMapper.convertRows(from: kpiData,
                                            dataFormats: dataFormats,
                                            selectedColumnIds: initialVisibleColumnIds,
                                            firstColumnId: firstColumnId,
                                            lineIndexes: lineIndexes,
                                            sortingCriteria: state.sortingCriteria)

        return (rows, headerState)
    }
}

extension ChartTableComponentFeature.Action {
    public enum Delegate: Equatable, Sendable {
        case chartButtonTapped(ChartTableComponentFeature.RowID)
        case selectorsToSyncChanged([Selectors]) //Replace by real filter object
        case selectorsButtonTapped(SelectorsFilterFeature.State)
        case sortingButtonTapped
    }
}

private enum CancelID {
    case deviceOrientationObserver
    case headerFilterOptionsObserver
}
