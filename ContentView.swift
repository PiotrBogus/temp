func groupItemsIntoTree(_ flatItems: [RawItem]) -> [ItemNode] {
    var lookup: [String: ItemNode] = [:]
    var roots: [ItemNode] = []

    // Create initial lookup
    for item in flatItems {
        lookup[item.id] = ItemNode(id: item.id, title: item.title)
    }

    // Assign children
    for item in flatItems {
        guard let node = lookup[item.id] else { continue }

        if let parentId = item.parentId, var parent = lookup[parentId] {
            parent.children.append(node)
            lookup[parentId] = parent
        } else {
            roots.append(node)
        }
    }

    // Recursively update tree from final lookup
    func attachChildren(for node: ItemNode) -> ItemNode {
        var updatedNode = node
        updatedNode.children = node.children.map { attachChildren(for: lookup[$0.id] ?? $0) }
        return updatedNode
    }

    return roots.map { attachChildren(for: $0) }
}
