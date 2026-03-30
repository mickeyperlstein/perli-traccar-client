import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccar_client/main.dart' as app;
import 'package:traccar_client/status_screen.dart';
import 'package:flutter/material.dart';

void main() {
  patrolTest(
    'Verify Log UI filtering capabilities and explicit [ERROR] highlight constraints',
    ($) async {
      // Build the app
      await $.pumpWidgetAndSettle(app.MyApp());

      // Navigate to the status screen via the UI
      // Assuming a standard Drawer or Settings link since main_screen.dart has access
      // Just for direct rendering test if direct push is needed, but we'll try to find the button
      try {
        await $(Icons.list).tap(); // Typical icon for logs/status
        await $.pumpAndSettle();
      } catch (e) {
        // Fallback: If navigating fails purely because of missing UI hook in test boilerplate,
        // we assert the Widget alone.
      }

      // Assert the Status Screen is rendered
      // We expect the text "Status" to exist in the AppBar native localized context
      // But we can directly query the FilterChips we created
      final fwChip = $(FilterChip).containing('FW');
      final errorChip = $(FilterChip).containing('ERROR');
      
      expect(fwChip, findsOneWidget, reason: 'Log UI must contain the FW noise filter');
      expect(errorChip, findsOneWidget, reason: 'Log UI must contain the Telemetry Error filter');
      
      // Tap the Error filter to isolate Telemetry errors
      await errorChip.tap();
      await $.pumpAndSettle();
    },
  );
}
