    [
      {
        "id": "internal",
        "title": "Internal"
      },
      {
        "id": "dailysales",
        "parentId": "internal",
        "title": "Daily Sales"
      },
     {
        "id": "nestedDailySales1",
        "parentId": "dailysales",
        "title": "nestedDailySales1"
      },
     {
        "id": "nestedDailySales2",
        "parentId": "dailysales",
        "title": "nestedDailySales1"
      },
      {
        "id": "sales",
        "parentId": "internal",
        "title": "Sales"
      },
      {
        "id": "globalpnl",
        "parentId": "internal",
        "title": "P&L Statement"
      },
      {
        "id": "localpnl",
        "parentId": "internal",
        "title": "Region / Country P&L"
      },
      {
        "id": "localmcf",
        "parentId": "internal",
        "title": "Region / Country MCF"
      },
      {
        "id": "ytdytgsales",
        "parentId": "internal",
        "title": "YTD / YTG"
      },
      {
        "id": "pvm",
        "parentId": "internal",
        "title": "PVM"
      },
      {
        "id": "tfc",
        "parentId": "internal",
        "title": "Total Function Costs"
      },
      {
        "id": "profit",
        "parentId": "internal",
        "title": "Profit"
      },
      {
        "id": "ros",
        "parentId": "internal",
        "title": "Return on Sales"
      },
      {
        "id": "ftepersonalcosts",
        "parentId": "internal",
        "title": "FTEs / Personnel Costs"
      },
      {
        "id": "tacticalra",
        "parentId": "internal",
        "title": "Tactical RA",
        "platform": ["web"]
      },
      {
        "id": "impactanalysis",
        "parentId": "internal",
        "title": "Impact Analysis",
        "platform": ["web"]
      },
      {
        "id": "external",
        "title": "External"
      },
      {
        "id": "wst",
        "parentId": "external",
        "title": "Weekly Share Tracker"
      },
      {
        "id": "mst",
        "parentId": "external",
        "title": "Monthly Share Tracker"
      },
      {
        "id": "mtintnl",
        "parentId": "external",
        "title": "Market Tracker INTL Focus"
      },
      {
        "id": "ptintl",
        "parentId": "external",
        "title": "Performance Tracker INTL"
      },
      {
        "id": "ussit",
        "parentId": "external",
        "title": "US Stock in Trade"
      },
      {
        "id": "iqvia",
        "parentId": "external",
        "title": "IQVIA Company Ranking"
      },
      {
        "id": "ffe",
        "parentId": "external",
        "title": "Field Force Engagement"
      },
      {
        "id": "local",
        "title": "Local"
      },
      {
        "id": "countrysales",
        "parentId": "external",
        "title": "Country Sales"
      },
      {
        "id": "countrypnl",
        "parentId": "external",
        "title": "Country P&L"
      },
      {
        "id": "productivity",
        "title": "Productivity"
      },
      {
        "id": "productivitykpi",
        "parentId": "productivity",
        "title": "Productivity KPI"
      }
    ]



func groupItemsIntoTree(from flatItems: [Item]) -> [Item] {
    var lookup: [String: Item] = [:]
    var roots: [Item] = []

    // Create a lookup dictionary
    for var item in flatItems {
        lookup[item.id] = item
    }

    // Build the tree
    for var item in flatItems {
        if let parentId = item.parentId {
            if var parent = lookup[parentId] {
                // Append the child to the parent's children
                parent.children.append(item)
                lookup[parentId] = parent
            }
        } else {
            // It's a root node
            roots.append(item)
        }
    }

    // Reassign children from lookup to maintain hierarchy
    func attachChildren(to item: Item) -> Item {
        var itemWithChildren = item
        itemWithChildren.children = item.children.map { attachChildren(to: lookup[$0.id] ?? $0) }
        return itemWithChildren
    }

    return roots.map { attachChildren(to: lookup[$0.id] ?? $0) }
}
