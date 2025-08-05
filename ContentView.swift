private static func groupItemsIntoTree(_ flatItems: [MenuItemApiMock]) -> [MenuItemFeature.State] {
    // 1. Build flat lookup map
    var lookup: [String: MenuItemFeature.State] = [:]

    for item in flatItems {
        lookup[item.id] = MenuItemFeature.State(
            id: item.id,
            title: item.title,
            parentId: item.parentId,
            childrens: []
        )
    }

    // 2. Build child relationships (child ID -> parent ID)
    for item in flatItems {
        guard let parentId = item.parentId else { continue }
        guard var parent = lookup[parentId], let child = lookup[item.id] else { continue }

        // Append child to the parent's children list
        parent.childrens.append(child)
        lookup[parentId] = parent
    }

    // 3. Recursive child population
    func attachChildren(for node: MenuItemFeature.State) -> MenuItemFeature.State {
        var updatedNode = node
        updatedNode.childrens = IdentifiedArrayOf(
            uniqueElements: node.childrens.map { child in
                attachChildren(for: lookup[child.id] ?? child)
            }
        )
        return updatedNode
    }

    // 4. Collect root nodes and attach full children recursively
    let rootNodes = flatItems
        .filter { $0.parentId == nil }
        .compactMap { item in
            guard let node = lookup[item.id] else { return nil }
            return attachChildren(for: node)
        }

    return rootNodes
}
