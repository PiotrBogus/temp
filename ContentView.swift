import Foundation
import GenieApi
import GenieCommonDomain

private let defaultMaxSelectableOptions = 20

public struct ChartOutputMapperLive: ChartOutputMapper {
    public func map(data: Components.Schemas.Chart, usign dateFormats: [DataFormatEntity]) -> ChartDataAggregate {
        let configDataFormats = createDataFormats(from: dateFormats) ?? .createMock()
        let legends = map(legends: data.legends, dataSets: data.dataSets)
        let chartData = map(dataSets: data.dataSets, dataPoints: data.dataPoints, with: dateFormats)
        let selectors = map(selectors: data.selectors)
        let dimensions = map(dimension: data.dimensionSelectors)

        return ChartDataAggregate(
            dataFormats: configDataFormats,
            legends: legends,
            data: chartData,
            selectors: selectors,
            dimensions: dimensions
        )
    }

    // MARK: - Dimensions Mapping

    private func map(dimension dto: [Components.Schemas.Selector]?) -> [GenieCommonDomain.Dimension] {
        guard let dto else { return [] }

        return dto.compactMap { selector in
            let id = extractIntFromGeneralId(selector.id)
            let name = selector.name
            let type = mapSelectorTypeToFilterType(selector._type)

            let options = selector.options.compactMap { option in
                let optionId = extractIntFromGeneralId(option.id)
                return GenieCommonDomain.Dimension.Option(id: optionId, title: option.title)
            }

            guard !options.isEmpty else { return nil }

            // Default to first 2 items
            let selectedOptions = prepareSelectedOptions(from: options)

            return GenieCommonDomain.Dimension(
                id: id,
                name: name,
                type: type,
                selectedOptions: selectedOptions,
                options: options,
                maxSelectableOptions: selector.maxMultiselectValues ?? defaultMaxSelectableOptions,
                allowsMultiselect: selector.allowMultiselect ?? false
            )
        }
    }

    // MARK: - Selectors Mapping

    private func map(selectors dto: [Components.Schemas.Selector]?) -> [Selectors] {
        guard let dto else { return [] }

        return dto.compactMap { selector in
            let id = extractIntFromGeneralId(selector.id)
            let name = selector.name

            // Since Selectors is a typealias for Dimension, we need to provide all required parameters
            // For selectors without options, we create a default option
            let defaultOption = Dimension.Option(id: id, title: name)

            return Dimension(
                id: id,
                name: name,
                type: .list,
                selectedOptions: [defaultOption],
                options: [defaultOption],
                maxSelectableOptions: defaultMaxSelectableOptions,
                allowsMultiselect: false
            )
        }
    }

    // MARK: - Data Mapping

    private func map(
        dataSets: [Components.Schemas.ChartDataSet],
        dataPoints: [Components.Schemas.ChartDataPoint],
        with dataFormats: [DataFormatEntity] = []
    ) -> [ChartDataWithVisibility<ChartData>] {
        var colorRotator = ChartColorRotator(includeNovartisBlue: true)

        // Create DrawableItem objects for each ChartDataSet
        var drawableItemsById: [Int: DrawableItem] = [:]
        for dataSet in dataSets {
            let drawableItem = mapChartDataSetToDrawableItem(dataSet, &colorRotator)
            drawableItemsById[dataSet.id] = drawableItem
        }

        // Group dataPoints by dataSetId
        let groupedPoints = Dictionary(grouping: dataPoints) { $0.dataSetId }

        var result: [ChartDataWithVisibility<ChartData>] = []

        for (dataSetId, points) in groupedPoints {
            guard let dataSet = dataSets.first(where: { $0.id == dataSetId }),
                let drawableItem = drawableItemsById[dataSetId]
            else { continue }

            let chartDataList = points.enumerated().compactMap { (index, point) -> ChartData? in
                return createChartDataFromPoint(
                    point: point,
                    dataSet: dataSet,
                    drawableItem: drawableItem,
                    index: index,
                    dataFormats: dataFormats
                )
            }

            let visibility = mapVisibilityToChartVisibility(dataSet.visibility)
            let chartDataWithVisibility = ChartDataWithVisibility(
                data: chartDataList,
                visibility: visibility
            )

            result.append(chartDataWithVisibility)
        }

        return result
    }

    // MARK: - Legends Mapping

    private func map(
        legends dto: [[Components.Schemas.ChartLegend]]?,
        dataSets: [Components.Schemas.ChartDataSet]
    ) -> [LegendItem] {
        guard let dto else { return [] }

        var colorRotator = ChartColorRotator(includeNovartisBlue: true)

        return dto.flatMap { legendGroup in
            legendGroup.enumerated().compactMap { (index, legend) -> LegendItem? in
                // FIXED: Use title.hashValue as ID (like in extension)
                let id = legend.title.hashValue
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

                return LegendItem(
                    id: id,
                    title: title,
                    color: color,
                    markType: markType,
                    associatedDrawableIds: associatedDrawableIds,
                    dataType: dataType
                )
            }
        }
    }

    // MARK: - Data Formats

    private func createDataFormats(from dataFormats: [DataFormatEntity])
        -> ChartFormatterConfig?
    {
        // Create number formatters from dataFormats
        var numberFormatters: [FormatterItem<NumberFormatter>] = []
        var dateFormatters: [FormatterItem<DateFormatter>] = []

        for apiFormat in dataFormats {
            // FIXED: Use apiFormat.id as FormatterItem id (not index)
            switch apiFormat.unitType {
            case .currency, .percentage, .numeric:
                let formatter = createNumberFormatter(from: apiFormat)
                numberFormatters.append(FormatterItem(id: apiFormat.id, formatter: formatter))
            case .date:
                let formatter = createDateFormatter(from: apiFormat)
                dateFormatters.append(FormatterItem(id: apiFormat.id, formatter: formatter))
            case .text:
                break
            }
        }

        // Use static decimal formatter as axis formatter
        let axisFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            return formatter
        }()

        return ChartFormatterConfig(
            axisFormatter: axisFormatter,
            supportedNumberFormatters: numberFormatters,
            supportedDateFormatters: dateFormatters
        )
    }

    private func createNumberFormatter(from apiFormat: DataFormatEntity)
        -> NumberFormatter
    {
        let formatter = NumberFormatter()

        switch apiFormat.unitType {
        case .currency:
            formatter.numberStyle = .currency
        case .percentage:
            formatter.numberStyle = .percent
        case .numeric:
            formatter.numberStyle = .decimal
        default:
            formatter.numberStyle = .decimal
        }

        formatter.maximumFractionDigits = apiFormat.digits ?? 2
        formatter.minimumFractionDigits = 0
        return formatter
    }

    private func createDateFormatter(from apiFormat: DataFormatEntity) -> DateFormatter
    {
        let formatter = DateFormatter()
        formatter.dateFormat = apiFormat.dateFormat ?? "MMM yyyy"
        return formatter
    }
}

// MARK: - Helper Functions

private extension ChartOutputMapperLive {

    func extractIntFromGeneralId(_ id: Components.Schemas.GeneralId) -> Int {
        switch id {
        case .integer(let intValue):
            return intValue
        case .string(let stringValue):
            return Int(stringValue) ?? 0
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

    func prepareSelectedOptions(
        from options: [GenieCommonDomain.Dimension.Option]
    ) -> [GenieCommonDomain.Dimension.Option] {
        // Default to first 2 items or all if less than 2
        return Array(options.prefix(2))
    }

    func mapChartDataSetToDrawableItem(
        _ dataSet: Components.Schemas.ChartDataSet, _ colorRotator: inout ChartColorRotator
    )
        -> DrawableItem
    {
        let name = "DataSet \(dataSet.id)"
        let isDashed = dataSet.lineStyle == .dashed
        let colorHex =
            extractColorFromSemanticColor(dataSet.color, with: &colorRotator) ?? "#000000"
        let opacity = 1.0
        let markType = mapDataPointDecorationToMarkType(dataSet.lineDecoration)

        return DrawableItem(
            id: dataSet.id,
            name: name,
            isDashed: isDashed,
            colorHex: colorHex,
            opacity: opacity,
            markType: markType
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
            return .circle
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
                    dimensionId: association.dimensionId,
                    value: association.value
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
        dataFormats: [DataFormatEntity]
    ) -> ChartData? {
        // Extract date from xValue
        guard let date = extractDateFromValue(point.xValue) else { return nil }

        // Extract numeric value from yValue
        guard let value = extractDoubleFromValue(point.yValue) else { return nil }

        // FIXED: Find formatter indices using dataFormatId from the point
        let dateFormatterIndex = findFormatterIndexForDataFormatId(
            point.xValue.dataFormatId, in: dataFormats)
        let valueFormatterIndex = findFormatterIndexForDataFormatId(
            point.yValue.dataFormatId, in: dataFormats)

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
            point.tooltip, date: date, dataFormats: dataFormats)

        // FIXED: Use dataSet.id for both legendId and componentId (not String conversion)
        return ChartData(
            legendId: dataSet.id,
            componentId: dataSet.id,
            date: date,
            dateFormatterIndex: dateFormatterIndex,
            valueFormatterIndex: valueFormatterIndex,
            value: value,
            type: dataType,
            index: index,
            tooltip: tooltip
        )
    }

    func extractDateFromValue(_ value: Components.Schemas.Value) -> Date? {
        guard let dateString = value.value?.stringValue else {
            return nil
        }
        
        // FIXED: Use DateParser.shared like in extension
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

    // FIXED: Method to find formatter index by dataFormatId
    func findFormatterIndexForDataFormatId(
        _ dataFormatId: Int,
        in dataFormats: [DataFormatEntity]
    ) -> Int? {
        // Match the dataFormatId to a formatter's id
        return dataFormats.firstIndex { $0.id == dataFormatId }
    }

    func findFormatterIndex(
        for type: DataFormatUnitType, in formats: [DataFormatEntity]
    ) -> Int? {
        return formats.firstIndex { format in
            format.unitType == type
        }
    }

    func createTooltipFromChartTooltip(
        _ tooltip: Components.Schemas.ChartTooltip?,
        date: Date,
        dataFormats: [DataFormatEntity]
    ) -> TooltipData? {
        guard let tooltip else { return nil }

        // Map rows from ChartTooltip to TooltipRow
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

                // FIXED: Find formatter index using dataFormatId
                let valueFormatterIndex = findFormatterIndexForDataFormatId(
                    dataValue.dataFormatId,
                    in: dataFormats
                )

                // Extract color if available
                let colorHex: String? = nil

                return TooltipRow(
                    label: label,
                    value: numericValue,
                    valueFormatterIndex: valueFormatterIndex,
                    colorHex: colorHex
                )
            } ?? []

        // FIXED: Find date formatter index using findFormatterIndex for .date type
        return TooltipData(
            label: tooltip.title ?? "",
            date: date,
            dateFormatterIndex: findFormatterIndex(for: .date, in: dataFormats),
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
