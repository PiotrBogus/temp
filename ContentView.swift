    public static func maxWidth(for values: [String], font: Font, weight: Font.Weight = .regular, maxWidth: CGFloat? = nil) async -> CGFloat {
        guard !values.isEmpty else { return 0 }

        var widths: [CGFloat] = []
        for value in values {
            let width = await width(for: value, font: font, weight: weight)
            widths.append(width)
        }

        let maxVal = widths.max() ?? 0
        return min(maxWidth ?? maxVal, maxVal)
    }
