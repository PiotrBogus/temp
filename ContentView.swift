    public func hideError(for index: Int) {
        guard checkboxes.endIndex < index else { return }
        let checkbox = checkboxes[index].checkbox
        checkbox.hideError()
        if errorContainer.isHidden, checkboxesWithErrorCount == .zero {
            state = .normal
        }
    }
