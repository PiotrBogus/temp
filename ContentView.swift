
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
           "id": "200300",
           "parentId": "200",
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


import AppCompositionDomain
import Foundation

public struct MenuItemDto: TreeItem, Sendable, Equatable, Decodable {
    public let id: Int
    public let title: String
    public let parentId: Int?
    public let externalKPIURL: String?
}
