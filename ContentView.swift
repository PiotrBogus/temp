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

        let formatterConfig = createDataFormats(from: dateFormats)

        // 🔴 JEDNO ŹRÓDŁO KOLORÓW
        var colorRotator = ChartColorRotator(includeNovartisBlue: true)

        // 🔴 DrawableItem tworzony RAZ
        let drawableItemsById: [Int: DrawableItem] =
            Dictionary(uniqueKeysWithValues: data.dataSets.map {
                ($0.id, mapChartDataSetToDrawableItem($0, &colorRotator))
            })

        let legends = map(
            legends: data.legends,
            drawableItemsById: drawableItemsById
        )

        let chartData = map(
            dataSets: data.dataSets,
            dataPoints: data.dataPoints,
            drawableItemsById: drawableItemsById,
            formatterConfig: formatterConfig
        )

        let selectors = map(selectors: data.selectors)
        let dimensions = map(dimensions: data.dimensionSelectors)

        return ChartDataAggregate(
            dataFormats: formatterConfig,
            legends: legends,
            data: chartData,
            selectors: selectors,
            dimensions: dimensions
        )
    }
}

// MARK: - Chart Data

private extension ChartOutputMapperLive {

    func map(
        dataSets: [Components.Schemas.ChartDataSet],
        dataPoints: [Components.Schemas.ChartDataPoint],
        drawableItemsById: [Int: DrawableItem],
        formatterConfig: ChartFormatterConfig
    ) -> [ChartDataWithVisibility<ChartData>] {

        dataPoints.enumerated().compactMap { index, point in
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
}

// MARK: - Legends

private extension ChartOutputMapperLive {

    func map(
        legends dto: [[Components.Schemas.ChartLegend]]?,
        drawableItemsById: [Int: DrawableItem]
    ) -> [LegendItem] {

        guard let dto else { return [] }

        return dto.flatMap { group in
            group.compactMap { legend in
                let associatedIds =
                    legend.associatedDataSetIds?.compactMap { Int($0) } ?? []

                let drawableItem =
                    associatedIds.compactMap { drawableItemsById[$0] }.first

                return LegendItem(
                    id: legend.title.hashValue,
                    title: legend.title,
                    color: drawableItem?.colorHex ?? "#000000",
                    markType: mapDataPointDecorationToMarkType(legend.lineDecoration),
                    associatedDrawableIds: associatedIds,
                    dataType: drawableItem.map { drawable in
                        switch drawable.markType {
                        case .circle, .square, .diamond:
                            return .projectedLine(drawable)
                        }
                    },
                    visibility: mapVisibilityToChartVisibility(legend.visibility)
                )
            }
        }
    }
}

// MARK: - DrawableItem

private extension ChartOutputMapperLive {

    func mapChartDataSetToDrawableItem(
        _ dataSet: Components.Schemas.ChartDataSet,
        _ colorRotator: inout ChartColorRotator
    ) -> DrawableItem {

        DrawableItem(
            id: dataSet.id,
            name: "DataSet \(dataSet.id)",
            isDashed: dataSet.lineStyle == .dashed,
            colorHex: extractColorFromSemanticColor(dataSet.color, with: &colorRotator) ?? "#000000",
            opacity: 1.0,
            markType: mapDataPointDecorationToMarkType(dataSet.lineDecoration),
            visibility: mapVisibilityToChartVisibility(dataSet.visibility)
        )
    }
}

// MARK: - Helpers (bez zmian logicznych)

private extension ChartOutputMapperLive {

    func createDataFormats(from dateFormats: [DataFormatEntity]) -> ChartFormatterConfig {
        ChartFormatterConfig(
            axisFormatter: leftAxisFormater,
            dataFormats: dateFormats
        )
    }

    func extractColorFromSemanticColor(
        _ color: Components.Schemas.SemanticColor?,
        with colorRotator: inout ChartColorRotator
    ) -> String? {
        color?.hexValue ?? colorRotator.nextColor()
    }

    func mapDataPointDecorationToMarkType(
        _ decoration: Components.Schemas.DataPointDecoration?
    ) -> MarkType {
        switch decoration {
        case .circle: return .circle
        case .square: return .square
        case .diamond: return .diamond
        default: return .circle
        }
    }

    func mapVisibilityToChartVisibility(
        _ visibility: Components.Schemas.ChartDataSetVisibility?
    ) -> ChartVisibility? {
        guard let visibility else { return nil }

        let handling: ChartVisibility.Handling =
            visibility.handling == .oneOf ? .oneOf :
            visibility.handling == .allOf ? .allOf : .none

        let associations =
            visibility.dimensionAssociations?.map {
                ChartVisibility.DimensionAssociation(
                    dimensionId: "\($0.dimensionId)",
                    value: "\($0.value)"
                )
            } ?? []

        return ChartVisibility(
            handling: handling,
            dimensionAssociations: associations
        )
    }
}
