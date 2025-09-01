import Domain
import Foundation

public struct TreeStructureBuilder<Result: TreeItemResult, Item: TreeItem> {
    private let itemMapper: (Item) -> Result

    public init(itemMapper: @escaping (Item) -> Result) {
        self.itemMapper = itemMapper
    }

    public func buildTree(_ flatItems: [Item]) -> [Result] {
        var lookup = makeLookup(from: flatItems)
        establishParentChildRelationships(in: &lookup, from: flatItems)
        return buildRootNodes(from: flatItems, using: lookup)
    }

    // MARK: - Step 1: Build Lookup
    private func makeLookup(from items: [Item]) -> [String: Result] {
        var lookup: [String: Result] = [:]
        for item in items {
            lookup[item.id] = itemMapper(item)
        }
        return lookup
    }

    // MARK: - Step 2: Establish Parent-Child Relationships
    private func establishParentChildRelationships(
        in lookup: inout [String: Result],
        from items: [Item]
    ) {
        for item in items {
            guard let parentId = item.parentId,
                  var parent = lookup[parentId],
                  let child = lookup[item.id]
            else { continue }

            parent.childrens.append(child)
            lookup[parentId] = parent
        }
    }

    // MARK: - Step 3: Recursive Child Attachment
    private func attachChildren(for node: Result, depth: Int, using lookup: [String: Result]) -> Result {
        var updatedNode = node
        updatedNode.depth = depth
        updatedNode.childrens = node.childrens.compactMap { child in
            let resolvedChild = lookup[child.id] ?? child
            return attachChildren(for: resolvedChild, depth: depth + 1, using: lookup)
        }
        return updatedNode
    }

    // MARK: - Step 4: Build Root Nodes
    private func buildRootNodes(from items: [Item], using lookup: [String: Result]) -> [Result] {
        items
            .filter { $0.parentId == nil }
            .compactMap {
                guard let node = lookup[$0.id] else { return nil }
                return attachChildren(for: node, depth: 0, using: lookup)
            }
    }
}
