Feature: App Startup Optimization
  As a traccar-client user
  I want the app to launch quickly
  So that I can access the main screen without delay

  Background:
    The current app initialization sequentially waits for:
    - Firebase.initializeApp() - network calls to Firebase
    - GeolocationService.init() - BackgroundGeolocation.ready() with native setup
    - PushService.init() - Firebase messaging registration
    These block runApp() and cause slow startup (3-5+ seconds)

  Scenario: Parallel Service Initialization
    Given the app main() function has multiple async service initializations
    When the app launches
    Then non-critical services should initialize in parallel using Future.wait()
    And critical services (Preferences, Firebase) should complete first
    And the main UI should render within 1 second

  Scenario: Deferred Non-Critical Initialization
    Given GeolocationService and PushService are not needed for initial UI
    When the app launches
    Then the main screen should render immediately after Preferences init
    And GeolocationService/PushService should init via post-frame callback
    And user should see the UI while services continue initializing

  Scenario: Lazy Service Access
    Given PushService is only needed for push notifications
    When the user opens the main screen
    Then PushService should only initialize when first notification is received
    Or when user explicitly enables tracking
    Not blocking initial app startup

  Notes:
    - Current timing: ~3-5s cold start on emulator
    - Target timing: <1s to first frame
    - Reference: lib/main.dart lines 22-29
    - Consider using WidgetsBinding.instance.addPostFrameCallback for deferred init
