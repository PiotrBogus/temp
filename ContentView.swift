import XCTest
@testable import Data

// swiftlint:disable force_try
final class TreeStructureBuilderTests: XCTestCase {
    func testBuildTree_SingleRootWithChildrenAndGrandchild() {
        // A
        // ├─ B
        // │  └─ D
        // └─ C
        let items: [ApiNode] = [
            .init(parentId: nil, id: "A"),
            .init(parentId: "A", id: "B"),
            .init(parentId: "A", id: "C"),
            .init(parentId: "B", id: "D")
        ]

        let builder = makeBuilder()
        let roots = builder.buildTree(items)

        XCTAssertEqual(roots.map(\.id), ["A"], "Should produce a single root A")

        let a = try! XCTUnwrap(find("A", in: roots))
        XCTAssertEqual(a.childrens.map(\.id), ["B", "C"], "A should have children B and C in insertion order")

        let b = try! XCTUnwrap(find("B", in: roots))
        XCTAssertEqual(b.childrens.map(\.id), ["D"], "B should have one child D")

        let c = try! XCTUnwrap(find("C", in: roots))
        XCTAssertTrue(c.childrens.isEmpty, "C should have no children")

        let d = try! XCTUnwrap(find("D", in: roots))
        XCTAssertTrue(d.childrens.isEmpty, "D should have no children")
    }

    func testBuildTree_MultipleRoots() {
        // A
        // └─ B
        // E  (second root)
        let items: [ApiNode] = [
            .init(parentId: nil, id: "A"),
            .init(parentId: "A", id: "B"),
            .init(parentId: nil, id: "E")
        ]

        let builder = makeBuilder()
        let roots = builder.buildTree(items)

        XCTAssertEqual(roots.map(\.id), ["A", "E"], "Should contain both roots in the order they appear among flat root items")

        let a = try! XCTUnwrap(find("A", in: roots))
        XCTAssertEqual(a.childrens.map(\.id), ["B"])

        let e = try! XCTUnwrap(find("E", in: roots))
        XCTAssertTrue(e.childrens.isEmpty)
    }

    func testBuildTree_OrphanChildWithMissingParent_IsNotIncluded() {
        // X has parent "Z" that does not exist → cannot become root and cannot be attached → should be excluded
        let items: [ApiNode] = [
            .init(parentId: nil, id: "A"),
            .init(parentId: "Z", id: "X") // orphan
        ]

        let builder = makeBuilder()
        let roots = builder.buildTree(items)

        XCTAssertEqual(roots.map(\.id), ["A"], "Only A should be a root")
        XCTAssertNil(find("X", in: roots), "Orphan X should not appear anywhere in the resulting tree")
    }

    func testBuildTree_DeepNesting() {
        // R → S → T → U (chain)
        let items: [ApiNode] = [
            .init(parentId: nil, id: "R"),
            .init(parentId: "R", id: "S"),
            .init(parentId: "S", id: "T"),
            .init(parentId: "T", id: "U")
        ]

        let builder = makeBuilder()
        let roots = builder.buildTree(items)

        XCTAssertEqual(roots.map(\.id), ["R"])
        XCTAssertNotNil(find("S", in: roots))
        XCTAssertNotNil(find("T", in: roots))
        XCTAssertNotNil(find("U", in: roots))

        let r = try! XCTUnwrap(find("R", in: roots))
        XCTAssertEqual(r.childrens.map(\.id), ["S"])
        let s = try! XCTUnwrap(find("S", in: roots))
        XCTAssertEqual(s.childrens.map(\.id), ["T"])
        let t = try! XCTUnwrap(find("T", in: roots))
        XCTAssertEqual(t.childrens.map(\.id), ["U"])
    }

    func testBuildTree_EmptyInput() {
        let builder = makeBuilder()
        let roots = builder.buildTree([])
        XCTAssertTrue(roots.isEmpty)
    }

    private func makeBuilder() -> TreeStructureBuilder<Node, ApiNode> {
        TreeStructureBuilder<Node, ApiNode> { api in
            Node(id: api.id, parentId: api.parentId, childrens: [])
        }
    }

    private func find(_ id: String, in roots: [Node]) -> Node? {
        var stack = roots
        while let node = stack.popLast() {
            if node.id == id { return node }
            stack.append(contentsOf: node.childrens)
        }
        return nil
    }
}
// swiftlint:enable force_try
