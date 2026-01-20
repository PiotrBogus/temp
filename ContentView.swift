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

    public func map(data: Components.Schemas.Chart, usign dateFormats: [DataFormatEntity]) -> ChartDataAggregate {
        let configDataFormats = createDataFormats(from: dateFormats)
        let legends = map(legends: data.legends, dataSets: data.dataSets)
        let chartData = map(dataSets: data.dataSets, dataPoints: data.dataPoints, with: configDataFormats)
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
        return ChartFormatterConfig(
            axisFormatter: leftAxisFormater,
            dataFormats: dateFormats
        )
    }

    // Note: Drawable items are connected to DataSets on the Data layer
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
                    isDefault: isOptionDefault(optionId: optionId, defaultValue: selector.defaultValue)
                )
            }

            guard !options.isEmpty else { return nil }

            let selectedOptions = prepareSelectedOptions(from: options, defaultValue: selector.defaultValue)

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
        return map(apiSelectors: dto)
    }

    private func map(selectors dto: [Components.Schemas.Selector]?) -> [FilterWithOptions] {
        guard let dto else { return [] }

        // exclude page_id selector
        let reducedDto = dto.filter { $0.name != "page_id" }
        let selectors = map(apiSelectors: reducedDto)

        return selectors
    }

    private func map(
        dataSets: [Components.Schemas.ChartDataSet],
        dataPoints: [Components.Schemas.ChartDataPoint],
        with formatterConfig: ChartFormatterConfig
    ) -> [ChartDataWithVisibility<ChartData>] {
        var colorRotator = ChartColorRotator(includeNovartisBlue: true)

        // Create DrawableItem objects for each ChartDataSet
        var drawableItemsById: [Int: DrawableItem] = [:]
        for dataSet in dataSets {
            let drawableItem = mapChartDataSetToDrawableItem(dataSet, &colorRotator)
            drawableItemsById[dataSet.id] = drawableItem
        }

        return dataPoints.enumerated().compactMap { (index, point) in
            guard let dataSet = dataSets.first(where: { $0.id == point.dataSetId }),
                let drawableItem = drawableItemsById[dataSet.id]
            else { return nil }
            let visibility = mapVisibilityToChartVisibility(point.visibility)

            guard
                let chartData = createChartDataFromPoint(
                    point: point,
                    dataSet: dataSet,
                    drawableItem: drawableItem,
                    index: index,
                    formatterConfig: formatterConfig
                )
            else { return nil }

            return ChartDataWithVisibility(
                data: chartData,
                visibility: visibility
            )
        }
    }

    private func map(
        legends dto: [[Components.Schemas.ChartLegend]]?,
        dataSets: [Components.Schemas.ChartDataSet]
    ) -> [LegendItem] {
        guard let dto else { return [] }
        
        var colorRotator = ChartColorRotator(includeNovartisBlue: true)

        return dto.flatMap { legendGroup in
            legendGroup.enumerated().compactMap { (index, legend) -> LegendItem? in
                let id = legend.title.hashValue  // Use hashValue as ID since legends don't have explicit IDs
                let title = legend.title

                // Extract color information
                let color =
                    extractColorFromSemanticColor(legend.color, with: &colorRotator) ?? "#000000"

                // Map lineDecoration to MarkType
                let markType = mapDataPointDecorationToMarkType(legend.lineDecoration)

                // Find associated dataSets
                let associatedDrawableIds =
                    legend.associatedDataSetIds?.compactMap { Int($0) } ?? []

                // Determine dataType from associated dataSets
                let dataType = determineDataTypeFromAssociatedDataSets(
                    associatedDataSetIds: associatedDrawableIds,
                    dataSets: dataSets,
                    colorRotator: &colorRotator
                )

                // Map visibility if available from legend object
                let visibility = mapVisibilityToChartVisibility(legend.visibility)

                return LegendItem(
                    id: id,
                    title: title,
                    color: color,
                    markType: markType,
                    associatedDrawableIds: associatedDrawableIds,
                    dataType: dataType,
                    visibility: visibility
                )
            }
        }
    }
}

// MARK: - Helper Functions

private extension ChartOutputMapperLive {

    func extractId(_ id: Components.Schemas.GeneralId) -> String {
        // GeneralId is an enum with .integer(Int) and .string(String) cases
        switch id {
        case .integer(let intValue):
            return "\(intValue)"
        case .string(let stringValue):
            return stringValue
        }
    }

    func mapSelectorTypeToFilterType(_ type: Components.Schemas.SelectorType?)
        -> GenieCommonDomain.Dimension.FilterType
    {
        guard let type = type else { return .list }

        let rawValue = type.rawValue
        switch rawValue {
        case "segmented":
            return .segmented
        default:
            return .list
        }
    }

    func isOptionDefault(
        optionId: String,
        defaultValue: DefaultValueType?
    ) -> Bool {
        guard let defaultValue else { return false }
        var defaultValues: [String] = []
        switch defaultValue {
        case let .integer(value):
            defaultValues.append("\(value)")
        case let .string(value):
            defaultValues.append(value)
        case let .integerArray(array):
            defaultValues.append(contentsOf: array.compactMap { "\($0)"})
        case let .stringArray(array):
            defaultValues.append(contentsOf: array)
        }

        return defaultValues.contains { $0 == optionId }
    }

    func prepareSelectedOptions(
        from options: [GenieCommonDomain.Dimension.Option],
        defaultValue: DefaultValueType?
    ) -> [GenieCommonDomain.Dimension.Option] {
        guard let defaultValue else { return [] }
        var defaultValues: [String] = []
        switch defaultValue {
        case let .integer(value):
            defaultValues.append("\(value)")
        case let .string(value):
            defaultValues.append(value)
        case let .integerArray(array):
            defaultValues.append(contentsOf: array.compactMap { "\($0)"})
        case let .stringArray(array):
            defaultValues.append(contentsOf: array)
        }

        return options.filter { option in
            defaultValues.contains { $0 == option.id }
        }
    }

    func mapChartDataSetToDrawableItem(
        _ dataSet: Components.Schemas.ChartDataSet, _ colorRotator: inout ChartColorRotator
    )
        -> DrawableItem
    {
        let name = "DataSet \(dataSet.id)"  // API doesn't provide name, use ID
        let isDashed = dataSet.lineStyle == .dashed
        let colorHex =
            extractColorFromSemanticColor(dataSet.color, with: &colorRotator) ?? "#000000"
        let opacity = 1.0  // Default opacity
        let markType = mapDataPointDecorationToMarkType(dataSet.lineDecoration)
        let visibility = mapVisibilityToChartVisibility(dataSet.visibility)

        return DrawableItem(
            id: dataSet.id,
            name: name,
            isDashed: isDashed,
            colorHex: colorHex,
            opacity: opacity,
            markType: markType,
            visibility: visibility
        )
    }

    func mapDataPointDecorationToMarkType(
        _ decoration: Components.Schemas.DataPointDecoration?
    ) -> MarkType {
        switch decoration {
        case .circle:
            return .circle
        case .square:
            return .square
        case .diamond:
            return .diamond
        case nil, .triangle, .cross, .some(.none):
            return .circle  // Default fallback
        }
    }

    func extractColorFromSemanticColor(
        _ color: Components.Schemas.SemanticColor?, with colorRotator: inout ChartColorRotator
    ) -> String? {
        guard let hex = color?.hexValue else {
            return colorRotator.nextColor()
        }

        return hex
    }

    func mapVisibilityToChartVisibility(
        _ visibility: Components.Schemas.ChartDataSetVisibility?
    ) -> ChartVisibility? {
        guard let visibility = visibility else { return nil }

        let handling: ChartVisibility.Handling
        if let handlingValue = visibility.handling {
            switch handlingValue {
            case .allOf:
                handling = .allOf
            case .oneOf:
                handling = .oneOf
            }
        } else {
            handling = .none
        }

        let dimensionAssociations =
            visibility.dimensionAssociations?.map { association in
                ChartVisibility.DimensionAssociation(
                    dimensionId: "\(association.dimensionId)",
                    value: "\(association.value)"
                )
            } ?? []

        return ChartVisibility(
            handling: handling,
            dimensionAssociations: dimensionAssociations
        )
    }

    func createChartDataFromPoint(
        point: Components.Schemas.ChartDataPoint,
        dataSet: Components.Schemas.ChartDataSet,
        drawableItem: DrawableItem,
        index: Int,
        formatterConfig: ChartFormatterConfig
    ) -> ChartData? {
        // Extract date from xValue
        guard let date = extractDateFromValue(point.xValue) else { return nil }

        // Extract numeric value from yValue
        guard let value = extractDoubleFromValue(point.yValue) else { return nil }

        // Find formatter indices using the dataFormatId from the point
        let dateFormatterIndex = findFormatterIndexForDateFormatter(
            from: point.xValue, in: formatterConfig)
        let valueFormatterIndex = findFormatterIndexForNumberFormatter(
            from: point.yValue, in: formatterConfig)

        // Determine data type
        let dataType: DataType
        switch dataSet.chartType {
        case .bar:
            dataType = .bar(drawableItem)
        case .line:
            dataType = .projectedLine(drawableItem)
        }

        // Create tooltip if available
        let tooltip = createTooltipFromChartTooltip(
            point.tooltip, date: date, formatterConfig: formatterConfig)

        // Format date as string for index
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        return ChartData(
            componentId: dataSet.id,
            date: date,
            dateFormatterIndex: dateFormatterIndex,
            valueFormatterIndex: valueFormatterIndex,
            value: value,
            type: dataType,
            tooltip: tooltip
        )
    }

    func extractDateFromValue(_ value: Components.Schemas.Value) -> Date? {
        guard let dateString = value.value?.stringValue else {
            return nil
        }

        return DateParser.shared.parseDate(from: dateString)
    }

    func extractDoubleFromValue(_ value: Components.Schemas.Value) -> Double? {
        // Try to extract numeric value from the value field
        if let doubleValue = value.value?.numberValue {
            return doubleValue
        }
        if let stringValue = value.value?.stringValue, let doubleValue = Double(stringValue) {
            return doubleValue
        }
        return nil
    }

    func findFormatterIndex(
        for type: String, in formats: [Components.Schemas.DataFormat]
    ) -> Int? {
        return formats.firstIndex { format in
            format.unitType.rawValue.lowercased().contains(type.lowercased())
        }
    }

    func findFormatterIndexForDataFormatId(
        _ dataFormatId: Int,
        in formatterConfig: ChartFormatterConfig
    ) -> Int? {
        // Match the dataFormatId to a formatter's id in the config
        if formatterConfig.supportedNumberFormatters.contains(where: { $0.id == dataFormatId }) {
            return dataFormatId
        }
        if formatterConfig.supportedDateFormatters.contains(where: { $0.id == dataFormatId }) {
            return dataFormatId
        }
        return nil
    }

    func findFormatterIndexForNumberFormatter(
        from value: Components.Schemas.Value,
        in formatterConfig: ChartFormatterConfig
    ) -> Int? {
        // Use the dataFormatId from the value to find the formatter index
        return findFormatterIndexForDataFormatId(value.dataFormatId, in: formatterConfig)
    }

    func findFormatterIndexForNumberFormatter(
        in formatterConfig: ChartFormatterConfig
    ) -> Int? {
        // Default to first number formatter if available
        return formatterConfig.supportedNumberFormatters.first?.id
    }

    func findFormatterIndexForDateFormatter(
        from value: Components.Schemas.Value,
        in formatterConfig: ChartFormatterConfig
    ) -> Int? {
        // Use the dataFormatId from the value to find the date formatter index
        return findFormatterIndexForDataFormatId(value.dataFormatId, in: formatterConfig)
    }

    func findFormatterIndexForDateFormatter(
        in formatterConfig: ChartFormatterConfig
    ) -> Int? {
        // Default to first date formatter if available
        return formatterConfig.supportedDateFormatters.first?.id
    }

    func createTooltipFromChartTooltip(
        _ tooltip: Components.Schemas.ChartTooltip?,
        date: Date,
        formatterConfig: ChartFormatterConfig
    ) -> TooltipData? {
        guard let tooltip else { return nil }

        // Map rows from ChartTooltip to TooltipRow
        // ChartTooltip.rows is [[Components.Schemas.Value]]? - array of arrays of Values
        let rows: [TooltipRow] =
            tooltip.rows?.enumerated().compactMap { (index, valueArray) in
                // Each row is an array of values, typically [label, value]
                guard valueArray.count >= 2 else { return nil }

                let labelValue = valueArray[0]
                let dataValue = valueArray[1]

                // Extract label from first value
                let label: String
                if let labelStr = labelValue.value?.stringValue {
                    label = labelStr
                } else {
                    label = "Row \(index)"
                }

                // Extract numeric value from second value
                guard let numericValue = extractDoubleFromValue(dataValue) else { return nil }

                // Find formatter index for the data value using the dataFormatId
                let valueFormatterIndex = findFormatterIndexForNumberFormatter(
                    from: dataValue, in: formatterConfig)

                // Extract color if available (would come from additional metadata)
                let colorHex: String? = nil

                return TooltipRow(
                    label: label,
                    value: numericValue,
                    valueFormatterIndex: valueFormatterIndex,
                    colorHex: colorHex
                )
            } ?? []

        return TooltipData(
            label: tooltip.title ?? "",
            date: date,
            dateFormatterIndex: findFormatterIndexForDateFormatter(
                in: formatterConfig),
            rows: rows
        )
    }

    func determineDataTypeFromAssociatedDataSets(
        associatedDataSetIds: [Int],
        dataSets: [Components.Schemas.ChartDataSet],
        colorRotator: inout ChartColorRotator
    ) -> DataType? {
        guard let firstId = associatedDataSetIds.first,
            let dataSet = dataSets.first(where: { $0.id == firstId })
        else { return nil }

        let drawableItem = mapChartDataSetToDrawableItem(dataSet, &colorRotator)

        switch dataSet.chartType {
        case .bar:
            return .bar(drawableItem)
        case .line:
            return .projectedLine(drawableItem)
        }
    }
}
