   static func maxWidth(
        for values: [String],
        font: Font,
        weight: Font.Weight = .regular,
        maxWidth: CGFloat? = nil
    ) async -> CGFloat {

        guard !values.isEmpty else { return 0 }

        // Parse font once (performance!)
        let parsed = SwiftUIFontMapper.parse(font)
        let uiFont = parsed.toUIFont()

        // Measure all values using cache
        var maxFound: CGFloat = 0

        for text in values {
            let w = await self.width(for: text, uiFont: uiFont)
            if w > maxFound { maxFound = w }
            if let limit = maxWidth, maxFound >= limit {
                return limit
            }
        }

        if let limit = maxWidth {
            return min(maxFound, limit)
        }
        return maxFound
    }
}
