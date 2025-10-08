import XCTest
@testable import YourModuleName // 🔹 zamień na nazwę swojego modułu

// MARK: - Mock types for testing

private struct MockItem: TreeItem, Equatable {
    let id: String
    let parentId: String?
}

private struct MockResult: TreeItemResult, Equatable {
    var id: String
    var parentId: String?
    var children: [MockResult] = []
}

// MARK: - Tests

final class TreeStructureBuilderTests: XCTestCase {

    func testBuildTree_CreatesCorrectHierarchy() {
        // Given
        let items: [MockItem] = [
            .init(id: "1", parentId: nil),
            .init(id: "2", parentId: "1"),
            .init(id: "3", parentId: "1"),
            .init(id: "4", parentId: "2")
        ]

        let builder = TreeStructureBuilder<MockResult, MockItem> { item in
            MockResult(id: item.id, parentId: item.parentId, children: [])
        }

        // When
        let tree = builder.buildTree(items)

        // Then
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree.first?.id, "1")
        XCTAssertEqual(tree.first?.children.map(\.id), ["2", "3"])
        XCTAssertEqual(tree.first?.children.first?.children.map(\.id), ["4"])
    }

    func testBuildTree_EmptyInput_ReturnsEmptyArray() {
        // Given
        let builder = TreeStructureBuilder<MockResult, MockItem> { item in
            MockResult(id: item.id, parentId: item.parentId, children: [])
        }

        // When
        let tree = builder.buildTree([])

        // Then
        XCTAssertTrue(tree.isEmpty)
    }

    func testBuildTree_HandlesMultipleRootItems() {
        // Given
        let items: [MockItem] = [
            .init(id: "1", parentId: nil),
            .init(id: "2", parentId: nil),
            .init(id: "3", parentId: "1"),
            .init(id: "4", parentId: "2")
        ]

        let builder = TreeStructureBuilder<MockResult, MockItem> { item in
            MockResult(id: item.id, parentId: item.parentId, children: [])
        }

        // When
        let tree = builder.buildTree(items)

        // Then
        XCTAssertEqual(tree.map(\.id), ["1", "2"])
        XCTAssertEqual(tree[0].children.map(\.id), ["3"])
        XCTAssertEqual(tree[1].children.map(\.id), ["4"])
    }

    func testBuildTree_HandlesUnorderedInput() {
        // Given
        let items: [MockItem] = [
            .init(id: "3", parentId: "1"),
            .init(id: "2", parentId: nil),
            .init(id: "1", parentId: nil),
            .init(id: "4", parentId: "3")
        ]

        let builder = TreeStructureBuilder<MockResult, MockItem> { item in
            MockResult(id: item.id, parentId: item.parentId, children: [])
        }

        // When
        let tree = builder.buildTree(items)

        // Then
        XCTAssertEqual(tree.map(\.id).sorted(), ["1", "2"]) // Dwa korzenie
        let root1 = tree.first(where: { $0.id == "1" })
        XCTAssertEqual(root1?.children.map(\.id), ["3"])
        XCTAssertEqual(root1?.children.first?.children.map(\.id), ["4"])
    }

    func testBuildTree_DeepHierarchy() {
        // Given
        let items: [MockItem] = [
            .init(id: "1", parentId: nil),
            .init(id: "2", parentId: "1"),
            .init(id: "3", parentId: "2"),
            .init(id: "4", parentId: "3"),
            .init(id: "5", parentId: "4")
        ]

        let builder = TreeStructureBuilder<MockResult, MockItem> { item in
            MockResult(id: item.id, parentId: item.parentId, children: [])
        }

        // When
        let tree = builder.buildTree(items)

        // Then
        XCTAssertEqual(tree.first?.id, "1")
        XCTAssertEqual(tree.first?.children.first?.children.first?.children.first?.children.first?.id, "5")
    }
}
