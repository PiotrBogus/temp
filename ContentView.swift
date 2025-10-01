import AppCompositionDomain
import Foundation

public struct TreeStructureBuilder<Result: TreeItemResult, Item: TreeItem> {
    private let itemMapper: (Item, Int) -> Result

    public init(itemMapper: @escaping (Item, Int) -> Result) {
        self.itemMapper = itemMapper
    }

    public func buildTree(_ flatItems: [Item], parentId: String? = nil, depth: Int = 0) -> [Result] {
        var result = flatItems
            .filter { $0.parentId == parentId }
            .map { itemMapper($0, depth) }

        result.indices.forEach { index in
            let children = buildTree(flatItems, parentId: result[index].id, depth: depth + 1)
            result[index].children = children
        }

        return result
    }
}
