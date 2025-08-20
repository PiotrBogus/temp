import Foundation
import ComposableArchitecture

@Reducer
public struct MenuFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        var items: IdentifiedArrayOf<MenuItemFeature.State> = []

        public init() {}
    }

    public enum Action {
        case delegate(Delegate)
        case onFirstAppear
        case didLoadMenu([MenuItemFeature.State])
        case dismiss
        case items(IdentifiedActionOf<MenuItemFeature>)
    }

    @Dependency(\.menuFeatureClient.log) private var log
    @Dependency(\.menuFeatureClient.loadMenuItems) private var loadMenuItems

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onFirstAppear:
                log(.debug, "menu did appear for first time")
                return loadMenu()
            case let .didLoadMenu(items):
                log(.debug, "did load menu")
                state.items = IdentifiedArrayOf(uniqueElements: items)
                return .none
            case .delegate:
                return .none
            case .dismiss:
                return .none
            case .items(.element(id: _, action: .delegate(.didTapItem(let id)))):
                return .none
            case .items:
                return .none
            }
        }
        .forEach(\.items, action: \.items) {
            MenuItemFeature()
        }
    }
}

extension MenuFeature {
    public enum Delegate: Sendable, Equatable {}
}

private extension MenuFeature {
    private func loadMenu() -> Effect<Action> {
        return .run { send in
            let groups = try? await loadMenuItems()
            await send(.didLoadMenu(groups ?? []))
        }
    }
}




import Foundation
import ComposableArchitecture
import Data

@Reducer
public struct MenuItemFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: TreeItemResult {
        public var childrens: IdentifiedArrayOf<MenuItemFeature.State> = []

        public let id: String
        let title: String
        public let parentId: String?
        var isExpanded: Bool = false
        var isSelected: Bool = false

        var isPossibleToExpand: Bool {
            childrens.isEmpty == false
        }
    }

    public indirect enum Action {
        case delegate(Delegate)
        case didTapItem(id: String)
        case childrens(IdentifiedActionOf<MenuItemFeature>)
    }

    @Dependency(\.menuItemFeatureClient.log) private var log

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .didTapItem(id):
                log(.debug, "did tap item: \(id)")
                if state.isPossibleToExpand {
                    state.isExpanded = !state.isExpanded
                    return .none
                } else {
                    state.isSelected = !state.isSelected
                    return .send(.delegate(.didTapItem(id: id)))
                }
            case .childrens(.element(id: _, action: .delegate(.didTapItem(let id)))):
                return .send(.delegate(.didTapItem(id: id)))
            case .childrens:
                return .none
            case .delegate:
                return .none
            }
        }
        .forEach(\.childrens, action: \.childrens) {
            MenuItemFeature()
        }
    }
}

extension MenuItemFeature {
    public enum Delegate: Sendable, Equatable {
        case didTapItem(id: String)
    }
}






import XCTest
import ComposableArchitecture
@testable import YourModuleName // ← Replace with the module that contains TreeStructerBuilder and the protocols

// MARK: - Test Doubles

struct ApiNode: ApiTreeItem {
    let parentId: String?
    let id: String
}

struct Node: TreeItemResult {
    typealias Child = Node
    var id: String
    var parentId: String?
    var childrens: IdentifiedArrayOf<Node> = []

    // Identifiable conformance is via `id`
    // Equatable synthesized is fine (all stored properties are Equatable)
}

final class TreeStructerBuilderTests: XCTestCase {

    private func makeBuilder() -> TreeStructerBuilder<Node, ApiNode> {
        TreeStructerBuilder<Node, ApiNode> { api in
            Node(id: api.id, parentId: api.parentId, childrens: [])
        }
    }

    private func find(_ id: String, in roots: [Node]) -> Node? {
        var stack = roots
        while let node = stack.popLast() {
            if node.id == id { return node }
            stack.append(contentsOf: node.childrens.elements)
        }
        return nil
    }

    // MARK: - Tests

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
}
