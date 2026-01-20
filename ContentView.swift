private func createColorsByDataSetId(
    from legends: [LegendItem]
) -> [Int: String] {
    var result: [Int: String] = [:]

    for legend in legends {
        for id in legend.associatedDrawableIds {
            result[id] = legend.color
        }
    }

    return result
}


