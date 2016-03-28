###Burndown

Needed environment:
- PT_TOKEN
- PT_PROJECT_IDS
- PT_START_DATE
- PT_RELEASE_NAME

PT_PROJECT_IDS="ID1,ID2"
PT_START_DATE is in format `"%Y-%m-%dT%H:%M:%SZ"`
`2015-12-04T21:00:00Z`

App gets iterations from >= PT_START_DATE till (including) the iteration where PT_RELEASE_NAME is. 



