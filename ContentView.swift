func circularBorderedImage(
    baseImage: UIImage,
    diameter: CGFloat = 44,
    borderWidth: CGFloat = 2,
    borderColor: UIColor = .white,
    backgroundColor: UIColor = .systemBlue
) -> UIImage {
    let size = CGSize(width: diameter, height: diameter)
    let renderer = UIGraphicsImageRenderer(size: size)
    
    return renderer.image { ctx in
        let rect = CGRect(origin: .zero, size: size)
        let circleRect = rect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
        let circlePath = UIBezierPath(ovalIn: circleRect)
        
        // tło (pełny okrąg)
        backgroundColor.setFill()
        circlePath.fill()
        
        // border (dokładnie wewnątrz okręgu, żeby nie był obcięty)
        borderColor.setStroke()
        circlePath.lineWidth = borderWidth
        circlePath.stroke()
        
        // oblicz rect dla obrazka (centrowany i skalowany)
        let inset = borderWidth * 2
        let imageRect = rect.insetBy(dx: inset, dy: inset)
        
        // zachowaj proporcje obrazka (skalowanie, żeby się zmieścił)
        let imageSize = baseImage.size
        let scale = min(imageRect.width / imageSize.width, imageRect.height / imageSize.height)
        let drawWidth = imageSize.width * scale
        let drawHeight = imageSize.height * scale
        let drawX = (rect.width - drawWidth) / 2
        let drawY = (rect.height - drawHeight) / 2
        let drawRect = CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
        
        // narysuj obrazek w środku
        baseImage.draw(in: drawRect)
    }
    .withRenderingMode(.alwaysOriginal)
}
