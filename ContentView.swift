func circularBorderedImage(
    baseImage: UIImage,
    size: CGFloat = 40,
    borderWidth: CGFloat = 2,
    borderColor: UIColor = .white,
    backgroundColor: UIColor = .systemBlue
) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
    return renderer.image { ctx in
        let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        let circlePath = UIBezierPath(ovalIn: rect)

        // fill background
        backgroundColor.setFill()
        circlePath.fill()

        // draw image inside circle (slightly inset)
        let inset = borderWidth * 2
        let imageRect = rect.insetBy(dx: inset, dy: inset)
        baseImage.draw(in: imageRect)

        // draw border
        borderColor.setStroke()
        circlePath.lineWidth = borderWidth
        circlePath.stroke()
    }.withRenderingMode(.alwaysOriginal) // ważne: zachowaj kolory!
}
