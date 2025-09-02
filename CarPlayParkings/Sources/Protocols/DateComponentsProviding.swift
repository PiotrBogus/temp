public protocol DateComponentsProviding: Sendable {
    func dateComponents(_ components: Set<Calendar.Component>, from start: Date, to end: Date) -> DateComponents
}

extension Calendar: DateComponentsProviding { }
