import ComposableArchitecture
import GenieCommonPresentation
import Foundation
import SwiftUI

@Reducer
public struct MenuFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        var items: IdentifiedArrayOf<MenuItemFeature.State> = []
        @Shared(.deviceOrientation) var deviceOrientation: DeviceOrientation = .unknown
        let preselectedItemId: String?
        
        public var appVersion: String = ""
        public var appBuild: String = ""
        public var appEnvironment: String = ""

        public init(preselectedItemId: String?) {
            self.preselectedItemId = preselectedItemId
        }
    }

    public enum Action: Sendable {
        case delegate(Delegate)
        case onFirstAppear
        case didLoadMenu([MenuItemFeature.State])
        case dismiss
        case items(IdentifiedActionOf<MenuItemFeature>)
    }

    @Dependency(\.menuFeatureClient.log) private var log
    @Dependency(\.menuFeatureClient.loadMenuItems) private var loadMenuItems
    @Dependency(\.menuFeatureClient.appInfoViewModel) private var appInfoViewModel

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onFirstAppear:
                log(.debug, "menu did appear for first time")
                if let viewModel = appInfoViewModel() {
                    state.appVersion = viewModel.version
                    state.appBuild = viewModel.build
                    state.appEnvironment = viewModel.environment
                }
                return loadMenu(selectedItemId: state.preselectedItemId)
            case let .didLoadMenu(items):
                log(.debug, "did load menu")
                state.items = IdentifiedArrayOf(uniqueElements: items)
                return .none
            case .delegate:
                return .none
            case .dismiss:
                return .send(.delegate(.dismissMenu))
            case let .items(.element(id: _, action: .delegate(.didTapItem(id, isExpand)))):
                if isExpand {
                    keepAncestorsAndCollapseOthers(expandedId: id, in: &state.items)
                    return .none
                } else {
                    deselectAllItems(beside: id, in: &state.items)
                    return .send(.delegate(.didSelectMenuItem(id)))
                }
            case .items:
                return .none
            }
        }
        .forEach(\.items, action: \.items) {
            MenuItemFeature()
        }
    }

    private func deselectAllItems(
        beside id: String,
        in items: inout IdentifiedArrayOf<MenuItemFeature.State>
    ) {
        for index in items.indices {
            items[index].isSelected = items[index].id == id
            deselectAllItems(beside: id, in: &items[index].identifiedArrayOfChildrens)
        }
    }

    @discardableResult
    private func keepAncestorsAndCollapseOthers(
        expandedId: String,
        in items: inout IdentifiedArrayOf<MenuItemFeature.State>
    ) -> Bool {
        var found = false
        for index in items.indices {
            if items[index].id == expandedId {
                found = true
                keepAncestorsAndCollapseOthers(
                    expandedId: expandedId,
                    in: &items[index].identifiedArrayOfChildrens
                )
            } else {
                let childHasExpanded = keepAncestorsAndCollapseOthers(
                    expandedId: expandedId,
                    in: &items[index].identifiedArrayOfChildrens
                )

                if childHasExpanded {
                    items[index].isExpanded = true
                    found = true
                } else {
                    items[index].isExpanded = false
                }
            }
        }

        return found
    }
}

extension MenuFeature {
    public enum Delegate: Sendable, Equatable {
        case dismissMenu
        case didSelectMenuItem(String)
    }
}

private extension MenuFeature {
    private func loadMenu(selectedItemId: String?) -> Effect<Action> {
        return .run { send in
            let groups = try? await loadMenuItems(selectedItemId)
            await send(.didLoadMenu(groups ?? []))
        }
    }
}



import ComposableArchitecture
import AppCompositionData
import AppCompositionDomain
import Dependencies
import DependenciesMacros
import Foundation
import GenieLogger
import Network

@DependencyClient
struct MenuFeatureClient: DependencyKey {
    var loadMenuItems: @Sendable (String?) async throws -> [MenuItemFeature.State]
    var log: @Sendable (_ level: LogLevel, _ message: String) -> Void
    var appInfoViewModel: @Sendable () -> AppInfoViewModel?

    static let liveValue: MenuFeatureClient = {
        @Dependency(\.logger) var logger
        @Dependency(\.menuRepository) var menuRepository
        @Dependency(\.appBundleRepository) var appBundleRepository

        @discardableResult
        @Sendable func expandParentsIfChildSelected(
            in items: inout [MenuItemFeature.State]
        ) -> Bool {
            var containsSelected = false
            for index in items.indices {
                var children = items[index].children
                let childContainsSelected = expandParentsIfChildSelected(in: &children)
                items[index].children = children
                if items[index].isSelected || childContainsSelected {
                    items[index].isExpanded = true
                    containsSelected = true
                }
            }
            return containsSelected
        }

        return MenuFeatureClient(
            loadMenuItems: { selectedItemId in
                do {
                    let apiItems = try await menuRepository.loadMenu()
                    let treeBuilder = TreeStructureBuilder<MenuItemFeature.State, MenuItem> { item  in
                        MenuItemFeature.State(
                            children: [],
                            id: item.id,
                            parentId: item.parentId,
                            title: item.title,
                            isSelected: item.id == selectedItemId
                        )
                    }
                    var tree = treeBuilder.buildTree(apiItems)
                    expandParentsIfChildSelected(in: &tree)
                    return tree
                } catch let error {
                    throw error
                }
            },
            log: { level, message in
                logger.log(level: level, message)
            },
            appInfoViewModel: {
                let appInfo = appBundleRepository.getAppInfo()
                return AppInfoViewModel(
                    version: appInfo.version ?? "",
                    build: appInfo.build ?? "",
                    environment: appInfo.environment?.rawValue.capitalized ?? ""
                )
            }
        )
    }()
}

extension DependencyValues {
    var menuFeatureClient: MenuFeatureClient {
        get { self[MenuFeatureClient.self] }
        set { self[MenuFeatureClient.self] = newValue }
    }
}



import Foundation
import ComposableArchitecture
import AppCompositionDomain

@Reducer
public struct MenuItemFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: TreeItemResult, Identifiable, Sendable {
        public var children: [MenuItemFeature.State] = []
        var identifiedArrayOfChildrens: IdentifiedArrayOf<MenuItemFeature.State> = []

        public let id: String
        public let parentId: String?
        let title: String
        var isExpanded: Bool = false
        var isSelected: Bool = false

        var isPossibleToExpand: Bool {
            children.isEmpty == false
        }
    }

    public indirect enum Action: Sendable {
        case onAppear
        case delegate(Delegate)
        case didTapItem(id: String)
        case children(IdentifiedActionOf<MenuItemFeature>)
    }

    @Dependency(\.menuItemFeatureClient.log) private var log

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.identifiedArrayOfChildrens = IdentifiedArrayOf(uniqueElements: state.children)
                return .none
            case let .didTapItem(id):
                log(.debug, "did tap item: \(id)")
                if state.isPossibleToExpand {
                    state.isExpanded = !state.isExpanded
                } else {
                    state.isSelected = !state.isSelected
                }
                return .send(.delegate(.didTapItem(id: id, isExpand: state.isPossibleToExpand)))
            case let .children(.element(id: _, action: .delegate(.didTapItem(id, isExpand)))):
                return .send(.delegate(.didTapItem(id: id, isExpand: isExpand)))
            case .children:
                return .none
            case .delegate:
                return .none
            }
        }
        .forEach(\.identifiedArrayOfChildrens, action: \.children) {
            MenuItemFeature()
        }
    }
}

extension MenuItemFeature {
    public enum Delegate: Sendable, Equatable {
        case didTapItem(id: String, isExpand: Bool)
    }
}



import Dependencies
import DependenciesMacros
import Foundation
import GenieLogger

@DependencyClient
struct MenuItemFeatureClient: DependencyKey {
    var log: @Sendable (_ level: LogLevel, _ message: String) -> Void

    static let liveValue: MenuItemFeatureClient = {
        @Dependency(\.logger) var logger

        return MenuItemFeatureClient(
            log: { level, message in
                logger.log(level: level, message)
            }
        )
    }()
}

extension DependencyValues {
    var menuItemFeatureClient: MenuItemFeatureClient {
        get { self[MenuItemFeatureClient.self] }
        set { self[MenuItemFeatureClient.self] = newValue }
    }
}
