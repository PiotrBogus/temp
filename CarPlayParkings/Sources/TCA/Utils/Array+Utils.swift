public extension Array {
    var hasOneElement: Bool {
        self.count == 1
    }
    var hasMultipleElements: Bool {
        self.count > 1
    }
}
