private func collapseAndDisableAllItems(
    items: IdentifiedArrayOf<AlternativeItemFeature.State>,
    isDisabled: Bool
) -> IdentifiedArrayOf<AlternativeItemFeature.State> {

    var result = items

    for index in result.indices {
        // collapse + disable bieżącego elementu
        result[index].isExpanded = false
        result[index].isDisabled = isDisabled

        // rekurencja tylko po jednym źródle prawdy
        result[index].identifiedArrayOfChildrens =
            collapseAndDisableAllItems(
                items: result[index].identifiedArrayOfChildrens,
                isDisabled: isDisabled
            )

        // jeżeli MUSISZ mieć `children` (np. legacy)
        result[index].children = Array(result[index].identifiedArrayOfChildrens)
    }

    return result
}
