//
//  IntlMarketTrackerNavigationFeature.swift
//  KpiIntlMarketTracker
//
//  Created by Daniel Satin on 04.08.2025.
//

import ComposableArchitecture
import GenieCommonPresentation

@Reducer
public struct IntlMarketTrackerNavigationFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {

        @Presents var destination: Destination.State?

        @Shared(.inMemory(SharedPresentationKeys.toolbarMenuTapped)) var isToolbarMenuTapped: Bool = false

        var path = StackState<Path.State>()
        var kpi: IntlMarketTrackerFeature.State

        public init() {
            // TODO Replace hardcoded pageID
            self.kpi = IntlMarketTrackerFeature.State(pageId: "10030")
        }
    }

    public enum Action: Sendable {
        case destination(PresentationAction<Destination.Action>)
        case kpi(IntlMarketTrackerFeature.Action)
        case onFirstAppear
        case path(StackActionOf<Path>)
        case toolbarBookmarkTapped
        case toolbarMenuTapped
        case toolbarSettingsTapped
    }

    public var body: some Reducer<State, Action> {
        Scope(state: \.kpi, action: \.kpi) {
            IntlMarketTrackerFeature()
        }

        Reduce { state, action in
            switch action {
            case let .kpi(.delegate(.selectorsButtonTapped(filterState))):
                state.destination = .selectorsFilter(filterState)
                return .none

            case let .kpi(.delegate(.chartButtonTapped(selectors))):
                print(selectors)
                state.destination = .chart(IntlMarketTrackerChartTableFeature.State(selectors: selectors))
                return .none

            case .destination(.presented(.chart(.delegate(.dismissChartAndTable)))):
                state.destination = nil
                return .none

            case .kpi:
                return .none

            case .onFirstAppear:
                return .none

            case .path:
                return .none

            case .destination:
                return .none

            case .toolbarBookmarkTapped:
                return .none

            case .toolbarMenuTapped:
                state.$isToolbarMenuTapped.withLock { $0 = true }
                return .none

            case .toolbarSettingsTapped:
                state.destination = .settings(IntlMarketTrackerSettingsFeature.State())
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
    }
}

extension IntlMarketTrackerNavigationFeature {
    @Reducer(state: .equatable, .sendable, action: .sendable)
    public enum Path {
        case kpiDrilldown(IntlMarketTrackerFeature)
    }

    @Reducer(state: .sendable, .equatable, action: .sendable)
    public enum Destination {
        case chart(IntlMarketTrackerChartTableFeature)
        case selectorsFilter(SelectorsFilterFeature)
        case settings(IntlMarketTrackerSettingsFeature)
    }
}






//
//  IntlMarketTrackerFeature.swift
//  KpiIntlMarketTracker
//
//  Created by Daniel Satin on 01.08.2025.
//

import ComposableArchitecture
import Foundation
import GenieCommonDomain
import GenieCommonPresentation
import KpiIntlMarketTrackerDomain

@Reducer
public struct IntlMarketTrackerFeature: Sendable {
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
        var headerSelectorPanel: KpiHeaderSelectorPanelFeature.State?
        
        var title: String = "INTL Market Tracker"
        var isBookmarkExists: Bool = false

        var dataFormats: [DataFormatEntity]?
        var marketTrackerKpiData: MarketTrackerKpiDataEntity?
        var inputSelectors: [SelectorParamEntity] = []
        var selectedHeaders: [Int: Int] = [:] /// [selected buttonIndex : columnId]


        var sortableColumns: [ColumnDefinition] = []
        var sortingCriteria: SortingCriteria = .init(order: .descending)

        var navigationTitle: String {
            "INTL Market Tracker"
        }

        let pageIdParameter: String = "page_id"

        public init(pageId: String) {
            self._isLoading = Shared(value: false)
            self._headerFilterOptions = Shared(value: [])
            self._selectedSelectors = Shared(value: [:])
            self.inputSelectors.append(SelectorParamEntity(selectorName: pageIdParameter, selectorValue: pageId))
        }
    }

    public enum Action: Sendable {
        case marketTrackerDataFetched(MarketTrackerKpiDataEntity, [DataFormatEntity])
        case dataMapped([KpiRowFeature<RowID, ValueID>.State], HeaderFeature.State)
        case delegate(Delegate)
        case deviceOrientationChanged
        case error(ErrorFeature.Action)
        case header(HeaderFeature.Action)
        case headerSelectorPanel(KpiHeaderSelectorPanelFeature.Action)
        case onError(Error)
        case onFirstAppear
        case selectorsChanged(IdentifiedArrayOf<OptionPickerRowFeature<Int>.State>)
        case table(TableFeature.Action)
    }

    @Dependency(\.intlMarketTrackerClient) private var intlMarketTrackerClient
    @Dependency(\.logger) private var logger
    @Dependency(\.kpiDataMapper) private var kpiDataMapper
    @Dependency(\.kpiRowMapper) private var kpiRowMapper

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
                    await send(.dataMapped(rows, headerState))
                }

            case let .dataMapped(rowStates, headerState):
                state.$isLoading.withLock { $0 = false }
                state.table = TableFeature.State(rows: .init(uniqueElements: rowStates))
                state.header = headerState

                let labels = state.headerFilterOptions
                    .sorted { $0.id < $1.id }
                    .map { header in
                        header.options.first(where: { $0.optionId == header.selectedOptionId })?.title ?? ""
                    }
                let sortingItems = state.sortableColumns.map {
                    SortingItem(id: $0.id, title: $0.title)
                }

                state.headerSelectorPanel = KpiHeaderSelectorPanelFeature.State(
                    labels: labels,
                    sortingItems: sortingItems,
                    sortingCriteria: state.sortingCriteria
                )
                return .none

            case .deviceOrientationChanged:
                guard let (rows, headerState) = convertDataToStates(
                    state: &state
                ) else {
                    return .none
                }
                return .run { send in
                    await send(.dataMapped(rows, headerState))
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
                        await send(.dataMapped(rows, headerState))
                    }
                }

            case .headerSelectorPanel(.filterButton(.delegate(.tapped))):
                return .send(.delegate(.selectorsButtonTapped(SelectorsFilterFeature.State(
                    isLoading: state.$isLoading,
                    headerFilterOptions: state.$headerFilterOptions,
                    selectedSelectors: state.$selectedSelectors
                ))))

            case let .headerSelectorPanel(.sortingButtonMenu(.delegate(.sortingCriteriaChanged(criteria)))):
                logger.debug("🔽🔼 Sorting criteria changed: \(criteria)")
                state.sortingCriteria = criteria

                guard let (rows, headerState) = convertDataToStates(
                    state: &state
                ) else {
                    return .none
                }

                return .run { send in
                    await send(.dataMapped(rows, headerState))
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
                var chartParams: [SelectorParamEntity] = state.inputSelectors
                chartParams.append(
                    SelectorParamEntity(
                        selectorName: "ROW_ID",
                        selectorValue: "\(rowID)"
                    )
                )
                print(chartParams)
                logger.debug("Tapped chart button with ID: \(rowID)")
                return .send(.delegate(.chartButtonTapped(chartParams)))

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
        .ifLet(\.headerSelectorPanel, action: \.headerSelectorPanel) { KpiHeaderSelectorPanelFeature() }
        .ifLet(\.error, action: \.error) { ErrorFeature() }
    }
}

// MARK: - Effects

extension IntlMarketTrackerFeature {
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
            async let marketTrackerKpiData = try await intlMarketTrackerClient.fetchIntMarketTracker(selectors: selectors)
            async let fetchedDataFormats = try intlMarketTrackerClient.fetchDataFormats()
            let _ = try await (fetchedDataFormats, marketTrackerKpiData)
            try await send(.marketTrackerDataFetched(marketTrackerKpiData, fetchedDataFormats))
        } catch: { error, send in
            await send(.onError(error))
        }
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
              let firstColumnId = kpiData.columns.first?.id
        else {
            return .none
        }

        let (headerButtons, columnGroupButtons, headerSegments, lineIndexes, initialVisibleColumnIds) =
        kpiDataMapper.convertDataToStatesAndHeaderElements(currentLayout: layout,
                                                           marketTrackerKpiData: kpiData,
                                                           selectedHeaders: state.selectedHeaders)

        var sortableColumns: [ColumnDefinition] = []
        for column in kpiData.columns {
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

extension IntlMarketTrackerFeature.Action {
    public enum Delegate: Equatable, Sendable {
        case chartButtonTapped([SelectorParamEntity])
        case selectorsButtonTapped(SelectorsFilterFeature.State)
        case sortingButtonTapped
    }
}

private enum CancelID {
    case deviceOrientationObserver
    case headerFilterOptionsObserver
}
