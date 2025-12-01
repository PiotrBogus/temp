    static func maxSymbolWidth(
        for systemNames: [String],
        font: Font,
        weight: Font.Weight = .regular,
        maxWidth: CGFloat? = nil
    ) async -> CGFloat {

        guard !systemNames.isEmpty else { return 0 }

        // Parse SwiftUI font once
        let parsed = SwiftUIFontMapper.parse(font)
        let uiFont = parsed.toUIFont(weight: weight)

        var maxFound: CGFloat = 0

        for name in systemNames {
            let w = await symbolWidth(for: name, uiFont: uiFont)
            if w > maxFound { maxFound = w }

            // if max width reached, no need to measure further
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


    static func totalSymbolWidth(
        for systemNames: [String],
        font: Font,
        weight: Font.Weight = .regular,
        padding: CGFloat = 0
    ) async -> CGFloat {

        guard !systemNames.isEmpty else { return 0 }

        // Parse SwiftUI font once
        let parsedFont = SwiftUIFontMapper.parse(font)
        let uiFont = parsedFont.toUIFont(weight: weight)

        var total: CGFloat = 0

        for (index, name) in systemNames.enumerated() {
            let width = await symbolWidth(for: name, uiFont: uiFont)
            total += width
            if index < systemNames.count - 1 {
                total += padding
            }
        }

        return total
    }
}
