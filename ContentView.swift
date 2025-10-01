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
                    let tree = treeBuilder.buildTree(apiItems)
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

