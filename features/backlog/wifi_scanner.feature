Feature: Wi-Fi Scanner Native Extraction
  As a traccar-client developer
  I want the client to safely request native Wi-Fi BSSID strings over MethodChannels
  So that I can broadcast them into local Geolocation Extras safely.

  Scenario: Wi-Fi Scanner encounters a Permission Denied event
    Given the Location Permission is not fully granted
    When the user triggers a manual location transmission
    Then the background execution should fail safely via PlatformException
    And the `[ ERROR ] USER HAS NOT AGREED TO WIFI DATA` tag should surface natively in the Log UI
    And the `TELEMETRY_FAILURES` scheme should contain `WIFI_PERMISSIONS_DENIED`
