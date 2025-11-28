public extension ColumnWidthCalculator {
    static func symbolWidth(
        for systemName: String,
        font: Font,
        weight: Font.Weight = .regular
    ) async -> CGFloat {

        // 🔑 Klucz cache
        let key = "symbol-\(systemName)-\(font.hashValue)"

        return await FontWidthCacheActor.shared.getOrCompute(key: key) {
            Self.measureSymbolWidth(systemName: systemName, font: font, weight: weight)
        }
    }

    private static func measureSymbolWidth(
        systemName: String,
        font: Font,
        weight: Font.Weight
    ) -> CGFloat {

        let uiWeight = FontWeightMapper.uiWeight(weight: weight)
        let uiFont = FontMapper.uiFont(font: font, uiWeight: uiWeight)

        guard let image = UIImage(systemName: systemName)?.withRenderingMode(.alwaysTemplate) else {
            return 0
        }

        // ⚖️ Symbol jest skalowany przez UIFontMetrics
        let metrics = UIFontMetrics(forTextStyle: .body)
        let scaledFont = metrics.scaledFont(for: uiFont)

        // Rozmiar symbolu zależy od font.pointSize
        let config = UIImage.SymbolConfiguration(pointSize: scaledFont.pointSize, weight: uiWeight)
        let scaledImage = image.applyingSymbolConfiguration(config) ?? image

        return ceil(scaledImage.size.width)
    }
}
