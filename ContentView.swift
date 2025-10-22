import AppCompositionDomain
import Dependencies
import Foundation
import GenieApi

public struct MenuRepositoryImpl: MenuRepository {
    @Dependency(\.apiClient) var apiClient

    public func loadMenu() async throws -> [MenuItemDto] {
        do {
//            return try MenuRepositoryImpl.prepareMock()
            let menu = try await apiClient.menuV1().ok.body
            switch menu {
            case .json(let items):
                return items.map {
                    MenuItemDto(
                        id: $0.id,
                        title: $0.title,
                        parentId: $0.parentId,
                        externalKPIURL: $0.externalKPIURL
                    )
                 }
//            }
        } catch {
            print(error)
            throw error
        }
    }
}

private extension MenuRepositoryImpl {
    private static func prepareMock() throws -> [MenuItemDto] {
        let data = Self.mockResponseJsonString.data(using: .utf8)!
        return try JSONDecoder().decode([MenuItemDto].self, from: data)
    }

    private static let mockResponseJsonString = """
       [
         {
           "id": 100,
           "title": "Core Financials"
         },
         {
           "id": 100100,
           "parentId": 100,
           "title": "Daily Sales"
         },
         {
           "id": 100200,
           "parentId": 100,
           "title": "Sales"
         },
         {
           "id": 100300,
           "parentId": 100,
           "title": "Profit"
         },
         {
           "id": 100400,
           "parentId": 100,
           "title": "PVM"
         },
         {
           "id": 100500,
           "parentId": 100,
           "title": "Total Functional Costs"
         },
         {
           "id": 100600,
           "parentId": 100,
           "title": "YTD / YTG"
         },
         {
           "id": 200,
           "title": "Business Insights"
         },
         {
           "id": 200100,
           "parentId": 200,
           "title": "Market Tracker"
         },     
         {
           "id": 200200,
           "parentId": 200,
           "title": "Performance Tracker INTL"
         },
         {
           "id": 200300,
           "parentId": 200,
           "title": "Field Force Engagement"
         },
         {
           "id": 200400,
           "parentId": 200,
           "title": "Tactical RA"
         },
         {
           "id": 200500,
           "parentId": 200,
           "title": "US Stock in Trade"
         },
         {
           "id": 200600,
           "parentId": 200,
           "title": "IQVIA Company Ranking"
         }
       ]
    """
}
