Feature: Logging High Signal-To-Noise Engine
  As a traccar-client developer
  I want a powerful, regex-capable Log UI natively inside the client
  So that I can easily diagnose background execution and monitor explicit `TELEMETRY_FAILURES` payloads.

  Scenario: Filtering background noise out of standard views
    Given the background tracking database generates verbose `TSSQLiteAppender` SQLite execution rows
    When I open the Status UI Page
    And the default view suppresses framework noise
    Then the SQLite execution row should be colorized dark grey
    And it should only appear when the "FW" filter toggle is manually activated.

  Scenario: Highlighting Telemetry Errors natively in the UI
    Given the background location heartbeat fires but Location Permissions were revoked
    When the system injects the `["WIFI_PERMISSIONS_DENIED"]` array into the payload
    Then the logger must output an explicit `[ ERROR ]` string matching the event
    And the Log UI must highlight the text natively in red and make it filterable under the "ERROR" UI chip.
