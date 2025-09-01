import Domain
import Foundation

public struct TreeStructureBuilder<Result: TreeItemResult, Item: TreeItem> {
    private let itemMapper: (Item) -> Result

    public init(itemMapper: @escaping (Item) -> Result) {
        self.itemMapper = itemMapper
    }

    public func buildTree(_ flatItems: [Item]) -> [Result] {
        // 1. Build flat lookup map
        var lookup: [String: Result] = [:]

        for item in flatItems {
            lookup[item.id] = itemMapper(item)
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
        func attachChildren(for node: Result, depth: Int) -> Result {
            var updatedNode = node
            updatedNode.depth = depth
            updatedNode.childrens = node.childrens.compactMap { child in
                return attachChildren(for: lookup[child.id] ?? child, depth: depth + 1)
            }
            return updatedNode
        }

        // 4. Collect root nodes and attach full children recursively
        let rootNodes: [Result] = flatItems
            .filter { $0.parentId == nil }
            .compactMap {
                guard let node = lookup[$0.id] else { return nil }
                return attachChildren(for: node, depth: 0)
            }

        return rootNodes
    }
}
