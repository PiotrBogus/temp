import AppCompositionDomain
import Foundation

public struct TreeStructureBuilder<Result: TreeItemResult, Item: TreeItem> {
    private let itemMapper: (Item) -> Result

    public init(itemMapper: @escaping (Item) -> Result) {
        self.itemMapper = itemMapper
    }

    public func buildTree(_ flatItems: [Item], parentId: String? = nil) -> [Result] {
        var result = flatItems
            .filter { $0.parentId == parentId }
            .map { itemMapper($0) }

        result.indices.forEach { index in
            let children = buildTree(flatItems, parentId: result[index].id)
            result[index].children = children
        }

        return result
    }
}
