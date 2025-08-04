func groupItemsIntoTree(_ flatItems: [RawItem]) -> [ItemNode] {
    var lookup: [String: ItemNode] = [:]
    var roots: [ItemNode] = []

    // Initialize all nodes
    for item in flatItems {
        lookup[item.id] = ItemNode(id: item.id, title: item.title)
    }

    // Assign children
    for item in flatItems {
        guard let node = lookup[item.id] else { continue }

        if let parentId = item.parentId, let parent = lookup[parentId] {
            parent.children.append(node) // This now works correctly
        } else {
            roots.append(node)
        }
    }

    return roots
}
