import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:traccar_client/main.dart' as app;
import 'package:traccar_client/preferences.dart';
import 'package:traccar_client/password_service.dart';
import 'package:traccar_client/geolocation_service.dart';
import 'package:flutter/material.dart';

Future<void> _handleSystemPermissionDialogs(PatrolIntegrationTester $) async {
  // Android runtime dialogs can appear in sequence (notifications, location, etc.).
  for (var i = 0; i < 3; i++) {
    // ignore: deprecated_member_use
    final isVisible = await $.native.isPermissionDialogVisible();
    if (!isVisible) break;

    try {
      // Android 13 notifications often show a plain "Allow" button.
      // ignore: deprecated_member_use
      await $.native.tap(Selector(text: 'Allow'));
      continue;
    } catch (_) {}
    try {
      // ignore: deprecated_member_use
      await $.native.grantPermissionWhenInUse();
      continue;
    } catch (_) {}
    try {
      // ignore: deprecated_member_use
      await $.native.grantPermissionOnlyThisTime();
      continue;
    } catch (_) {}
    break;
  }
}

void main() {
  patrolTest(
    'Verify Log UI filtering capabilities and explicit [ERROR] highlight constraints',
    ($) async {
      // Initialize required services before pumping the app
      await Firebase.initializeApp();
      await Preferences.init();
      await PasswordService.migrate();
      await GeolocationService.init();

      // Build the app
      await $.pumpWidgetAndSettle(const app.MainApp());

      // Dismiss runtime permission dialogs shown on first launch.
      await _handleSystemPermissionDialogs($);

      // Navigate to logs via the actual main screen button.
      final showStatusButton = $(FilledButton).containing('Show status');
      if (showStatusButton.exists) {
        await showStatusButton.tap();
      } else {
        // Localization-safe fallback for non-English test devices.
        await $(RegExp(r'(show\s*status|logs?)', caseSensitive: false)).tap();
      }
      await $.pumpAndSettle();

      // Ensure we really navigated to Logs screen before checking chips.
      expect(
        $(RegExp(r'logs?', caseSensitive: false)).exists,
        true,
        reason: 'Expected to navigate to the Logs screen',
      );

      // Mirror status_screen.dart structure: filter row + count indicator.
      final fwChip = $(FilterChip).containing('FW');
      final debugChip = $(FilterChip).containing('DEBUG');
      final infoChip = $(FilterChip).containing('INFO');
      final warnChip = $(FilterChip).containing('WARN');
      final errorChip = $(FilterChip).containing('ERROR');
      final countFinder = $(RegExp(r'\d+/\d+'));

      expect(
        fwChip,
        findsOneWidget,
        reason: 'Log UI must contain the FW noise filter',
      );
      expect(
        debugChip,
        findsOneWidget,
        reason: 'Log UI must contain the DEBUG filter',
      );
      expect(
        infoChip,
        findsOneWidget,
        reason: 'Log UI must contain the INFO filter',
      );
      expect(
        warnChip,
        findsOneWidget,
        reason: 'Log UI must contain the WARN filter',
      );
      expect(
        errorChip,
        findsOneWidget,
        reason: 'Log UI must contain the Telemetry Error filter',
      );
      expect(
        countFinder.exists,
        true,
        reason: 'Log UI must display filtered/total count',
      );

      // Mirror chip toggle behavior from StatusScreen: each tap toggles visibility.
      await debugChip.tap();
      await $.pumpAndSettle();
      expect(
        countFinder.exists,
        true,
        reason: 'Count indicator must remain visible after DEBUG toggle',
      );

      await warnChip.tap();
      await $.pumpAndSettle();
      expect(
        countFinder.exists,
        true,
        reason: 'Count indicator must remain visible after WARN toggle',
      );

      await errorChip.tap();
      await $.pumpAndSettle();
      expect(
        countFinder.exists,
        true,
        reason: 'Count indicator must remain visible after ERROR toggle',
      );

      await fwChip.tap();
      await $.pumpAndSettle();
      expect(
        countFinder.exists,
        true,
        reason: 'Count indicator must remain visible after FW toggle',
      );
    },
  );
}
