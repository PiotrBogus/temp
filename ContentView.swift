{
  "title": "Global Sales Performance Dashboard",
  "selectors": [
    {
      "id": 1,
      "name": "region",
      "title": "Region",
      "defaultValue": "eu",
      "resetSelectors": false,
      "type": 0,
      "allowMultiselect": false,
      "synchronizationGroupId": 10,
      "options": [
        { "id": "eu", "title": "Europe", "subtitle": "EU Market", "isEnabled": true },
        { "id": "na", "title": "North America", "subtitle": "NA Market", "isEnabled": true },
        { "id": "apac", "title": "APAC", "subtitle": "Asia-Pacific", "isEnabled": true }
      ],
      "maxMultiselectValues": 1
    },
    {
      "id": 2,
      "name": "product",
      "title": "Product Line",
      "defaultValue": "all",
      "resetSelectors": false,
      "type": 0,
      "allowMultiselect": true,
      "synchronizationGroupId": 11,
      "options": [
        { "id": "p1", "title": "Product A", "subtitle": "Electronics", "isEnabled": true },
        { "id": "p2", "title": "Product B", "subtitle": "Household", "isEnabled": true },
        { "id": "p3", "title": "Product C", "subtitle": "Accessories", "isEnabled": true }
      ],
      "maxMultiselectValues": 3
    }
  ],
  "columnSelectors": [
    {
      "id": 100,
      "title": "Metric Set",
      "type": 0,
      "allowMultiselect": true,
      "maxSelectedColumns": 3,
      "minSelectedColumns": 1,
      "defaultColumnsIds": [1, 2, 3],
      "options": [1, 2, 3, 4, 5]
    }
  ],
  "columns": [
    {
      "id": 1,
      "title": "Sales",
      "subtitle": "Total Sales (USD)",
      "sortable": true,
      "valueAlignment": 1,
      "titleAlignment": 0,
      "multiValueHandling": { "handling": 0, "togglingGroupId": 20 },
      "coloring": 0
    },
    {
      "id": 2,
      "title": "Revenue",
      "subtitle": "Total Revenue (USD)",
      "sortable": true,
      "valueAlignment": 1,
      "titleAlignment": 0,
      "multiValueHandling": { "handling": 0, "togglingGroupId": 20 },
      "coloring": 0
    },
    {
      "id": 3,
      "title": "Profit Margin",
      "subtitle": "Margin (%)",
      "sortable": true,
      "valueAlignment": 1,
      "titleAlignment": 0,
      "multiValueHandling": { "handling": 0, "togglingGroupId": 20 },
      "coloring": 1
    },
    {
      "id": 4,
      "title": "Volume",
      "subtitle": "Units Sold",
      "sortable": true,
      "valueAlignment": 1,
      "titleAlignment": 0,
      "multiValueHandling": { "handling": 0, "togglingGroupId": 20 },
      "coloring": 0
    },
    {
      "id": 5,
      "title": "Growth",
      "subtitle": "Year-over-Year Growth (%)",
      "sortable": true,
      "valueAlignment": 1,
      "titleAlignment": 0,
      "multiValueHandling": { "handling": 0, "togglingGroupId": 20 },
      "coloring": 2
    }
  ],
  "layouts": [
    {
      "type": { "platform": 0, "orientation": 1 },
      "visibleColumnGroups": [
        {
          "id": 1,
          "title": "Financial Metrics",
          "associatedSelectorIds": [1, 2]
        }
      ],
      "visibleColumns": [
        {
          "toggleColumnIds": [1, 2, 3],
          "defaultColumnId": 1,
          "measurePosition": 0,
          "hasRightBorder": true,
          "columnGroupId": 1,
          "associatedSelectors": [
            { "selectorId": 1, "selectorType": 0 }
          ]
        }
      ],
      "selectorsRowContent": [1, 2]
    }
  ],
  "dataFormats": [
    {
      "id": 1,
      "unitType": 0,
      "unitOfMeasure": "USD",
      "digits": 0,
      "dateFormat": "",
      "isBold": true,
      "isItalic": false
    },
    {
      "id": 2,
      "unitType": 1,
      "unitOfMeasure": "%",
      "digits": 1,
      "dateFormat": "",
      "isBold": false,
      "isItalic": false
    },
    {
      "id": 3,
      "unitType": 2,
      "unitOfMeasure": "pcs",
      "digits": 0,
      "dateFormat": "",
      "isBold": false,
      "isItalic": false
    }
  ],
  "rows": [
    {
      "id": 2001,
      "hasChart": true,
      "hasDrillDown": true,
      "rowType": 0,
      "drillDownInfo": {
        "drillDownId": 100,
        "drillDownParamType": "product",
        "drillDownTitle": "Product A Sales Details"
      },
      "cells": [
        { "columnId": 1, "values": [{ "valueId": 1, "value": "1200000", "dataFormatId": 1, "coloring": 0 }] },
        { "columnId": 2, "values": [{ "valueId": 2, "value": "3800000", "dataFormatId": 1, "coloring": 0 }] },
        { "columnId": 3, "values": [{ "valueId": 3, "value": "28.5", "dataFormatId": 2, "coloring": 1 }] },
        { "columnId": 4, "values": [{ "valueId": 4, "value": "46000", "dataFormatId": 3, "coloring": 0 }] },
        { "columnId": 5, "values": [{ "valueId": 5, "value": "12.4", "dataFormatId": 2, "coloring": 2 }] }
      ],
      "parentId": 0,
      "groupId": 1
    },
    {
      "id": 2002,
      "hasChart": false,
      "hasDrillDown": true,
      "rowType": 0,
      "drillDownInfo": {
        "drillDownId": 101,
        "drillDownParamType": "product",
        "drillDownTitle": "Product B Sales Details"
      },
      "cells": [
        { "columnId": 1, "values": [{ "valueId": 6, "value": "980000", "dataFormatId": 1, "coloring": 0 }] },
        { "columnId": 2, "values": [{ "valueId": 7, "value": "3100000", "dataFormatId": 1, "coloring": 0 }] },
        { "columnId": 3, "values": [{ "valueId": 8, "value": "24.3", "dataFormatId": 2, "coloring": 1 }] },
        { "columnId": 4, "values": [{ "valueId": 9, "value": "38000", "dataFormatId": 3, "coloring": 0 }] },
        { "columnId": 5, "values": [{ "valueId": 10, "value": "9.1", "dataFormatId": 2, "coloring": 2 }] }
      ],
      "parentId": 0,
      "groupId": 1
    },
    {
      "id": 2003,
      "hasChart": false,
      "hasDrillDown": false,
      "rowType": 0,
      "drillDownInfo": null,
      "cells": [
        { "columnId": 1, "values": [{ "valueId": 11, "value": "450000", "dataFormatId": 1, "coloring": 0 }] },
        { "columnId": 2, "values": [{ "valueId": 12, "value": "1500000", "dataFormatId": 1, "coloring": 0 }] },
        { "columnId": 3, "values": [{ "valueId": 13, "value": "19.8", "dataFormatId": 2, "coloring": 1 }] },
        { "columnId": 4, "values": [{ "valueId": 14, "value": "21000", "dataFormatId": 3, "coloring": 0 }] },
        { "columnId": 5, "values": [{ "valueId": 15, "value": "4.3", "dataFormatId": 2, "coloring": 2 }] }
      ],
      "parentId": 0,
      "groupId": 1
    }
  ]
}
