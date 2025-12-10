import Foundation
import GenieApi
import GenieCommonDomain

private let defaultMaxSelectableOptions = 20

extension Operations.MSTV1Chart.Output {
    // Note: Drawable items are connected to DataSets on the Data layer
    public func createDimensions() -> [GenieCommonDomain.Dimension] {
        guard case .ok(let response) = self else { return [] }

        let chart: Components.Schemas.Chart
        do {
            chart = try response.body.json
        } catch {
            return []
        }

        guard let dimensionSelectors = chart.dimensionSelectors else { return [] }

        return dimensionSelectors.compactMap { selector in
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
                maxSelectableOptions: selector.maxMultiselectValues
                    ?? defaultMaxSelectableOptions,
                allowsMultiselect: selector.allowMultiselect ?? false
            )
        }
    }

    public func createSelectors() -> [Selectors] {
        guard case .ok(let response) = self else { return [] }

        let chart: Components.Schemas.Chart
        do {
            chart = try response.body.json
        } catch {
            return []
        }

        guard let selectors = chart.selectors else { return [] }

        return selectors.compactMap { selector in
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
                maxSelectableOptions: nil ?? defaultMaxSelectableOptions,
                allowsMultiselect: false
            )
        }
    }

    public func createData(with formatterConfig: ChartFormatterConfig)
        -> [ChartDataWithVisibility<ChartData>]
    {
        guard case .ok(let response) = self else { return [] }

        let chart: Components.Schemas.Chart
        do {
            chart = try response.body.json
        } catch {
            return []
        }

        let dataSets = chart.dataSets
        let dataPoints = chart.dataPoints

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
                    formatterConfig: formatterConfig
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

    public func createLegends() -> [LegendItem] {
        guard case .ok(let response) = self else { return [] }

        let chart: Components.Schemas.Chart
        do {
            chart = try response.body.json
        } catch {
            return []
        }

        guard let legends = chart.legends else { return [] }

        let dataSets = chart.dataSets

        var colorRotator = ChartColorRotator(includeNovartisBlue: true)

        return legends.flatMap { legendGroup in
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
}

// MARK: - Helper Functions

extension Operations.MSTV1Chart.Output {

    func extractIntFromGeneralId(_ id: Components.Schemas.GeneralId) -> Int {
        // GeneralId is an enum with .integer(Int) and .string(String) cases
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
        // TODO: Sync with API in the future to support dynamic selection logic
        // Default to first 2 items or all if less than 2
        return Array(options.prefix(2))
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

        return ChartData(
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







import Foundation
import GenieApi
import GenieCommonDomain

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

    // Note: Drawable items are connected to DataSets on the Data layer

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
                maxSelectableOptions: selector.maxMultiselectValues,
                allowsMultiselect: selector.allowMultiselect ?? false
            )
        }
    }

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
                maxSelectableOptions: nil,
                allowsMultiselect: false
            )
        }
    }

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

    private func map(
        legends dto: [[Components.Schemas.ChartLegend]]?,
        dataSets: [Components.Schemas.ChartDataSet]
    ) -> [LegendItem] {
        guard let dto else { return [] }

        var colorRotator = ChartColorRotator(includeNovartisBlue: true)

        return dto.flatMap { legendGroup in
            legendGroup.enumerated().compactMap { (index, legend) -> LegendItem? in
                let id = index  // Use index as ID since legends don't have explicit IDs
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

    // NOTE: Data formats are now provided from a separate endpoint
    // This method converts API DataFormats to domain DataFormatEntity models
    private func mapDataFormats(from dataFormats: [Components.Schemas.DataFormat]? = nil)
        -> [GenieCommonDomain.DataFormatEntity]
    {
        let formats = dataFormats ?? []

        return formats.compactMap { apiFormat in
            mapDataFormat(apiFormat)
        }
    }

    private func mapDataFormat(_ apiFormat: Components.Schemas.DataFormat) -> GenieCommonDomain
        .DataFormatEntity?
    {
        let id = apiFormat.id
        let unitType = mapDataFormatUnitType(apiFormat.unitType)
        let digits = apiFormat.digits
        let unitOfMeasure = apiFormat.unitOfMeasure
        let dateFormat = apiFormat.dateFormat

        return GenieCommonDomain.DataFormatEntity(
            id: id,
            unitType: unitType,
            digits: digits,
            unitOfMeasure: unitOfMeasure,
            dateFormat: dateFormat
        )
    }

    private func mapDataFormatUnitType(_ unitType: Components.Schemas.DataFormatUnitType)
        -> GenieCommonDomain.DataFormatUnitType
    {
        switch unitType {
        case .currency:
            return .currency
        case .percentage:
            return .percentage
        case .numeric:
            return .numeric
        case .date:
            return .date
        case .text:
            return .text
        }
    }

    // Legacy method for creating formatters (deprecated - use mapDataFormats instead)
    private func createDataFormats(from dataFormats: [DataFormatEntity])
        -> ChartFormatterConfig?
    {
        // Create number formatters from dataFormats
        var numberFormatters: [FormatterItem<NumberFormatter>] = []
        var dateFormatters: [FormatterItem<DateFormatter>] = []

        for (index, apiFormat) in dataFormats.enumerated() {
            switch apiFormat.unitType {
            case .currency, .percentage, .numeric:
                let formatter = createNumberFormatter(from: apiFormat)
                numberFormatters.append(FormatterItem(id: index, formatter: formatter))
            case .date:
                let formatter = createDateFormatter(from: apiFormat)
                dateFormatters.append(FormatterItem(id: index, formatter: formatter))
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
        // GeneralId is an enum with .integer(Int) and .string(String) cases
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
        // TODO: Sync with API in the future to support dynamic selection logic
        // Default to first 2 items or all if less than 2
        return Array(options.prefix(2))
    }

    func findSelectedOption(
        from defaultValue: Components.Schemas.DefaultValueType,
        in options: [GenieCommonDomain.Dimension.Option]
    ) -> GenieCommonDomain.Dimension.Option? {
        switch defaultValue {
        case .integer(let intValue):
            return options.first { $0.id == intValue }
        case .string(let stringValue):
            if let intValue = Int(stringValue) {
                return options.first { $0.id == intValue }
            }
            return options.first { $0.title == stringValue }
        case .stringArray(let stringArray):
            if let firstString = stringArray.first, let intValue = Int(firstString) {
                return options.first { $0.id == intValue }
            }
            return options.first { stringArray.contains($0.title) }
        case .integerArray(let intArray):
            if let firstInt = intArray.first {
                return options.first { $0.id == firstInt }
            }
            return nil
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

        // Find formatter indices
        let dateFormatterIndex = findFormatterIndex(for: .date, in: dataFormats)
        let valueFormatterIndex = findFormatterIndex(for: .numeric, in: dataFormats)

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

        return ChartData(
            legendId: dataSet.id,
            componentId: String(dataSet.id),
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
        // The Value type contains valueId, value, and dataFormatId references
        // Try to parse the actual value string as a date
        if let dateString = value.value?.stringValue {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: dateString) {
                return date
            }
            // Try alternative date formats
            let alternativeFormatter = DateFormatter()
            alternativeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = alternativeFormatter.date(from: dateString) {
                return date
            }
        }
        // Fallback: create a placeholder date based on valueId if value parsing fails
        let timeInterval = TimeInterval(value.valueId * 86400)  // Convert to days
        return Date(timeIntervalSince1970: timeInterval)
    }

    func extractDoubleFromValue(_ value: Components.Schemas.Value) -> Double? {
        // Try to extract numeric value from the value field
        if let doubleValue = value.value?.numberValue {
            return doubleValue
        }
        if let stringValue = value.value?.stringValue, let doubleValue = Double(stringValue) {
            return doubleValue
        }
        // Fallback: use valueId as placeholder numeric value
        return nil
    }

    func findFormatterIndex(
        for type: DataFormatUnitType, in formats: [DataFormatEntity]
    ) -> Int? {
        return formats.firstIndex { format in
            format.unitType == type
        }
    }

    func findFormatterIndex(
        forDataFormatId dataFormatId: Int,
        in formats: [DataFormatEntity]
    ) -> Int? {
        // Match the dataFormatId to a formatter index
        // Assuming the dataFormatId from the API corresponds to the index in the formats array
        return dataFormatId < formats.count ? dataFormatId : nil
    }

    func createTooltipFromChartTooltip(
        _ tooltip: Components.Schemas.ChartTooltip?,
        date: Date,
        dataFormats: [DataFormatEntity]
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

                // Find formatter index for the data value
                let valueFormatterIndex = findFormatterIndex(
                    forDataFormatId: dataValue.dataFormatId,
                    in: dataFormats
                )

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
