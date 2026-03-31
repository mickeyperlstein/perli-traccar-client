Feature: Bluetooth Native Extraction
  As a traccar-client developer
  I want the client to safely request native BLE device strings over MethodChannels
  So that I can broadcase them locally into Android SQLite databases alongside Heartbeats.

  Scenario: Bluetooth Scanner encounters Permission Denied events
    Given the BLUETOOTH_SCAN permission is artificially rejected by the OS
    When the heartbeat triggers the ScannerService Orchestrator manually
    Then the system should gracefully trap the Bluetooth Exception
    And the `TELEMETRY_FAILURES` array must explicitly attach `BT_PERMISSIONS_DENIED` back into the heartbeat JSON payload.
