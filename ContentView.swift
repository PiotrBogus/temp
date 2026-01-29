let intersection = Set(section.items.map(\.id))
    .intersection(store.selectedItems.map(\.id))

switch intersection.count {
case 0:
    return .empty
case section.items.count:
    return .fullySelectedItems
default:
    return .partialySelectedItems
}
