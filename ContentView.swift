Select a definition

Genie.NextApi
Genie.NextGen.Api
 1.0 
OAS 3.0
https://ci-api-next.dev.genie.novartis.net/swagger/../swagger/v1/swagger.json

Authorize
Common

FeatureFlags

FinanceWatchlist

MarketTracker


POST
/mst/v1/data
Provides data part of KPI, this part is loaded always when selectors are changed



POST
/mst/v1/tableData
Returns the table data for the Market Tracker KPI. This endpoint is called whenever selectors are changed.


Parameters
Cancel
No parameters

Request body

application/json
The query model containing the list of selected filters.

Edit Value
Schema
{
  "selectors": [
    {
      "selectorName": "string",
      "selectorValue": "string"
    }
  ]
}
Execute
Clear
Responses
Curl

curl -X 'POST' \
  'https://ci-api-next.dev.genie.novartis.net/mst/v1/tableData' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "selectors": [
    {
      "selectorName": "string",
      "selectorValue": "string"
    }
  ]
}'
Request URL
https://ci-api-next.dev.genie.novartis.net/mst/v1/tableData
Server response
Code	Details
401
Undocumented
Error: response status is 401

Response headers
 access-control-allow-origin: * 
 content-length: 0 
 date: Tue,25 Nov 2025 11:21:49 GMT 
 strict-transport-security: max-age=15724800; includeSubDomains 
 www-authenticate: Bearer,Bearer 
Responses
Code	Description	Links
200	
OK

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "title": "string",
  "selectors": [
    {
      "id": 0,
      "name": "string",
      "title": "string",
      "defaultValue": "string",
      "resetSelectors": true,
      "type": 0,
      "allowMultiselect": true,
      "synchronizationGroupId": 0,
      "options": [
        {
          "id": "string",
          "title": "string",
          "subtitle": "string",
          "isEnabled": true
        }
      ],
      "maxMultiselectValues": 0
    }
  ],
  "columnSelectors": [
    {
      "id": 0,
      "title": "string",
      "type": 0,
      "allowMultiselect": true,
      "maxSelectedColumns": 0,
      "minSelectedColumns": 0,
      "defaultColumnsIds": [
        0
      ],
      "options": [
        0
      ]
    }
  ],
  "columns": [
    {
      "id": 0,
      "title": "string",
      "subtitle": "string",
      "sortable": true,
      "valueAlignment": 0,
      "titleAlignment": 0,
      "multiValueHandling": {
        "handling": 0,
        "togglingGroupId": 0
      },
      "coloring": 0
    }
  ],
  "layouts": [
    {
      "type": {
        "platform": 0,
        "orientation": 0
      },
      "visibleColumnGroups": [
        {
          "id": 0,
          "title": "string",
          "associatedSelectorIds": [
            0
          ]
        }
      ],
      "visibleColumns": [
        {
          "toggleColumnIds": [
            0
          ],
          "defaultColumnId": 0,
          "measurePosition": 0,
          "hasRightBorder": true,
          "columnGroupId": 0,
          "associatedSelectors": [
            {
              "selectorId": 0,
              "selectorType": 0
            }
          ]
        }
      ],
      "selectorsRowContent": [
        0
      ]
    }
  ],
  "dataFormats": [
    {
      "id": 0,
      "unitType": 0,
      "unitOfMeasure": "string",
      "digits": 0,
      "dateFormat": "string",
      "isBold": true,
      "isItalic": true
    }
  ],
  "rows": [
    {
      "id": 0,
      "hasChart": true,
      "hasDrillDown": true,
      "rowType": 0,
      "drillDownInfo": {
        "drillDownId": 0,
        "drillDownParamType": "string",
        "drillDownTitle": "string"
      },
      "cells": [
        {
          "columnId": 0,
          "values": [
            {
              "valueId": 0,
              "value": "string",
              "dataFormatId": 0,
              "coloring": 0
            }
          ]
        }
      ],
      "parentId": 0,
      "groupId": 0
    }
  ]
}
No links
410	
Endpoint version no longer supported

No links

POST
/mst/v1/chart
Provides Chart part of KPI, this part is loaded always when selectors are changed



Schemas
