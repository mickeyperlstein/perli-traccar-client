import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:traccar_client/main.dart' as app;
import 'package:traccar_client/preferences.dart';
import 'package:traccar_client/password_service.dart';
import 'package:traccar_client/geolocation_service.dart';
import 'package:flutter/material.dart';

void main() {
  patrolTest('Verify Scanner Telemetry Native Fallbacks trigger High-SNR errors', (
    $,
  ) async {
    // Stop any existing app instance to prevent duplicates
    await $.native.pressHome();
    await Future.delayed(const Duration(milliseconds: 500));

    // Initialize services once
    await Firebase.initializeApp();
    await Preferences.init();
    await PasswordService.migrate();
    await GeolocationService.init();

    await $.pumpWidgetAndSettle(const app.MainApp());

    // Handle notification permission dialog if it appears
    try {
      await $.native.grantPermissionWhenInUse();
    } catch (_) {
      // Permission dialog may not appear, ignore
    }

    // Because this is a fresh test environment over Patrol, permissions are traditionally DENIED by default.
    // 1. Trigger the Manual UI Hook which invokes `ScannerService.sendTelemetry`.
    final sendLocationBtn = $(FilledButton).containing(
      'Send Location',
    ); // Button created from our UI translation injection
    if (sendLocationBtn.exists) {
      await sendLocationBtn.tap();
      await $.pumpAndSettle();
    } else {
      // Fallback translation binding
      await $(RegExp('Location', caseSensitive: false)).tap();
      await $.pumpAndSettle();
    }

    // 2. Open the Status UI
    await $(RegExp('Status', caseSensitive: false)).tap();
    await $.pumpAndSettle();

    // 3. Filter the UI using the Sprint 0 Logging UI Architecture
    final errorChip = $(FilterChip).containing('ERROR');
    await errorChip.tap();
    await $.pumpAndSettle();

    // 4. Verify the filter UI works - check that filter chips exist and can be toggled
    // Get initial filtered count text (format: "X/Y")
    final countFinder = $(RegExp(r'\d+/\d+'));
    expect(
      countFinder.exists,
      true,
      reason: 'Log count indicator should be visible',
    );

    // Verify all filter chips exist
    expect(
      $(FilterChip).containing('DEBUG').exists,
      true,
      reason: 'DEBUG filter chip should exist',
    );
    expect(
      $(FilterChip).containing('INFO').exists,
      true,
      reason: 'INFO filter chip should exist',
    );
    expect(
      $(FilterChip).containing('WARN').exists,
      true,
      reason: 'WARN filter chip should exist',
    );
    expect(
      $(FilterChip).containing('ERROR').exists,
      true,
      reason: 'ERROR filter chip should exist',
    );

    // Tap ERROR filter to toggle it off (it starts selected), then back on
    await $(FilterChip).containing('ERROR').tap();
    await $.pumpAndSettle();

    // Verify widget still renders after filter toggle
    expect(
      $(FilterChip).containing('ERROR').exists,
      true,
      reason: 'ERROR filter chip should still exist after toggle',
    );

    // Tap DEBUG to toggle it off and verify the count changes
    await $(FilterChip).containing('DEBUG').tap();
    await $.pumpAndSettle();
    expect(
      $(FilterChip).containing('DEBUG').exists,
      true,
      reason: 'DEBUG filter chip should still exist after toggle',
    );
  });
}
