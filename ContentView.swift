import ComposableArchitecture
import Foundation

struct TreeStructerBuilder<Result: TreeItemResult, ApiItem: ApiTreeItem> {
    private let itemMapper: (ApiItem) -> Result

    init(itemMapper: @escaping (ApiItem) -> Result) {
        self.itemMapper = itemMapper
    }

    func buildTree(_ flatItems: [ApiItem]) -> [Result] {
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
        func attachChildren(for node: Result) -> Result {
            var updatedNode = node
            updatedNode.childrens = IdentifiedArrayOf(
                uniqueElements: node.childrens.compactMap { child in
                    return attachChildren(for: lookup[child.id] ?? child)
                }
            )
            return updatedNode
        }


        // 4. Collect root nodes and attach full children recursively
        let rootNodes: [Result] = flatItems
            .filter { $0.parentId == nil }
            .compactMap {
                guard let node = lookup[$0.id] else { return nil }
                return attachChildren(for: node)
            }

        return rootNodes
    }
}



import Foundation

protocol ApiTreeItem {
    var parentId: String? { get }
    var id: String { get }
}



import Foundation
import ComposableArchitecture

protocol TreeItemResult: Identifiable, Equatable {
    associatedtype Child: TreeItemResult
    var id: String { get }
    var parentId: String? { get }
    var childrens: IdentifiedArrayOf<Child> { get set }
}
