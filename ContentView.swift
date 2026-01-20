import Foundation
import GenieApi
import GenieCommonDomain

private let defaultMaxSelectableOptions = 20

public struct ChartOutputMapperLive: ChartOutputMapper {
    private let leftAxisFormater: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    public func map(
        data: Components.Schemas.Chart,
        usign dateFormats: [DataFormatEntity]
    ) -> ChartDataAggregate {

        let configDataFormats = createDataFormats(from: dateFormats)

        // ⭐️ COLOR SYNC CHANGE – jeden wspólny rotator
        var colorRotator = ChartColorRotator(includeNovartisBlue: true)

        let legends = map(
            legends: data.legends,
            dataSets: data.dataSets,
            colorRotator: &colorRotator
        )

        let chartData = map(
            dataSets: data.dataSets,
            dataPoints: data.dataPoints,
            with: configDataFormats,
            colorRotator: &colorRotator
        )

        let selectors = map(selectors: data.selectors)
        let dimensions = map(dimensions: data.dimensionSelectors)

        return ChartDataAggregate(
            dataFormats: configDataFormats,
            legends: legends,
            data: chartData,
            selectors: selectors,
            dimensions: dimensions
        )
    }

    private func createDataFormats(from dateFormats: [DataFormatEntity]) -> ChartFormatterConfig {
        ChartFormatterConfig(
            axisFormatter: leftAxisFormater,
            dataFormats: dateFormats
        )
    }

    // MARK: - Selectors

    private func map(apiSelectors dto: [Components.Schemas.Selector]?) -> [FilterWithOptions] {
        guard let dto else { return [] }

        return dto.compactMap { selector in
            let id = extractId(selector.id)
            let name = selector.name
            let title = selector.title ?? selector.name
            let type = mapSelectorTypeToFilterType(selector._type)

            let options = selector.options.compactMap { option in
                let optionId = extractId(option.id)
                return GenieCommonDomain.Dimension.Option(
                    id: optionId,
                    title: option.title,
                    isEnabled: option.isEnabled ?? true,
                    isDefault: isOptionDefault(
                        optionId: optionId,
                        defaultValue: selector.defaultValue
                    )
                )
            }

            guard !options.isEmpty else { return nil }

            let selectedOptions = prepareSelectedOptions(
                from: options,
                defaultValue: selector.defaultValue
            )

            return GenieCommonDomain.Dimension(
                id: id,
                name: name,
                title: title,
                type: type,
                selectedOptions: selectedOptions,
                options: options,
                maxSelectableOptions: selector.maxMultiselectValues
                    ?? defaultMaxSelectableOptions,
                allowsMultiselect: selector.allowMultiselect ?? false
            )
        }
    }

    private func map(dimensions dto: [Components.Schemas.Selector]?) -> [FilterWithOptions] {
        map(apiSelectors: dto)
    }

    private func map(selectors dto: [Components.Schemas.Selector]?) -> [FilterWithOptions] {
        guard let dto else { return [] }
        return map(apiSelectors: dto.filter { $0.name != "page_id" })
    }

    // MARK: - Chart data

    private func map(
        dataSets: [Components.Schemas.ChartDataSet],
        dataPoints: [Components.Schemas.ChartDataPoint],
        with formatterConfig: ChartFormatterConfig,
        colorRotator: inout ChartColorRotator // ⭐️ COLOR SYNC CHANGE
    ) -> [ChartDataWithVisibility<ChartData>] {

        var drawableItemsById: [Int: DrawableItem] = [:]

        for dataSet in dataSets {
            let drawableItem = mapChartDataSetToDrawableItem(
                dataSet,
                &colorRotator
            )
            drawableItemsById[dataSet.id] = drawableItem
        }

        return dataPoints.enumerated().compactMap { index, point in
            guard
                let dataSet = dataSets.first(where: { $0.id == point.dataSetId }),
                let drawableItem = drawableItemsById[dataSet.id]
            else { return nil }

            guard let chartData = createChartDataFromPoint(
                point: point,
                dataSet: dataSet,
                drawableItem: drawableItem,
                index: index,
                formatterConfig: formatterConfig
            ) else { return nil }

            return ChartDataWithVisibility(
                data: chartData,
                visibility: mapVisibilityToChartVisibility(point.visibility)
            )
        }
    }

    // MARK: - Legends

    private func map(
        legends dto: [[Components.Schemas.ChartLegend]]?,
        dataSets: [Components.Schemas.ChartDataSet],
        colorRotator: inout ChartColorRotator // ⭐️ COLOR SYNC CHANGE
    ) -> [LegendItem] {

        guard let dto else { return [] }

        return dto.flatMap { legendGroup in
            legendGroup.compactMap { legend in
                let id = legend.title.hashValue
                let title = legend.title

                let color = extractColorFromSemanticColor(
                    legend.color,
                    with: &colorRotator
                ) ?? "#000000"

                let associatedDrawableIds =
                    legend.associatedDataSetIds?.compactMap(Int.init) ?? []

                let dataType = determineDataTypeFromAssociatedDataSets(
                    associatedDataSetIds: associatedDrawableIds,
                    dataSets: dataSets,
                    colorRotator: &colorRotator
                )

                return LegendItem(
                    id: id,
                    title: title,
                    color: color,
                    markType: mapDataPointDecorationToMarkType(legend.lineDecoration),
                    associatedDrawableIds: associatedDrawableIds,
                    dataType: dataType,
                    visibility: mapVisibilityToChartVisibility(legend.visibility)
                )
            }
        }
    }
}

// MARK: - Helpers (BEZ ZMIAN)

private extension ChartOutputMapperLive {

    func extractId(_ id: Components.Schemas.GeneralId) -> String {
        switch id {
        case .integer(let intValue): return "\(intValue)"
        case .string(let stringValue): return stringValue
        }
    }

    func mapSelectorTypeToFilterType(
        _ type: Components.Schemas.SelectorType?
    ) -> GenieCommonDomain.Dimension.FilterType {
        type?.rawValue == "segmented" ? .segmented : .list
    }

    func isOptionDefault(
        optionId: String,
        defaultValue: DefaultValueType?
    ) -> Bool {
        guard let defaultValue else { return false }

        let values: [String]
        switch defaultValue {
        case .integer(let v): values = ["\(v)"]
        case .string(let v): values = [v]
        case .integerArray(let v): values = v.map(String.init)
        case .stringArray(let v): values = v
        }

        return values.contains(optionId)
    }

    func prepareSelectedOptions(
        from options: [GenieCommonDomain.Dimension.Option],
        defaultValue: DefaultValueType?
    ) -> [GenieCommonDomain.Dimension.Option] {

        guard let defaultValue else { return [] }

        let values: [String]
        switch defaultValue {
        case .integer(let v): values = ["\(v)"]
        case .string(let v): values = [v]
        case .integerArray(let v): values = v.map(String.init)
        case .stringArray(let v): values = v
        }

        return options.filter { values.contains($0.id) }
    }
}
