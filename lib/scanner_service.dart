import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

class ScannerService {
  static const MethodChannel _channel = MethodChannel('org.traccar.client/scanner');

  // WHO: Antigravity Strategy Orchestrator
  // WHY: We need to pull contextual hardware data (WiFi/BT) concurrently to enrich the Traccar Payload without crashing the Flutter framework if permissions are missing.
  // HOW: By wrapping `invokeMethod` inside individual try-catch blocks and parsing PlatformExceptions, we aggregate successful strings and push missing permissions into a `TELEMETRY_FAILURES` array instead.
  static Future<Map<String, dynamic>> scanAll() async {
    final Map<String, dynamic> outputPayload = {
      'WIFI': '',
      'BT': '',
      'LastUpdate': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    
    final List<String> telemetryFailures = [];

    // Attempt WiFi
    try {
      final String wifiData = await _channel.invokeMethod('scanWiFiSimple');
      outputPayload['WIFI'] = wifiData;
    } on PlatformException catch (e) {
      telemetryFailures.add('WIFI_PERMISSIONS_DENIED');
      await _logError('WiFi scan error', e);
    } catch (e) {
      telemetryFailures.add('WIFI_SCANNER_FAULT');
      await _logError('WiFi native scan error', e);
    }

    // Attempt Bluetooth
    try {
      final String btData = await _channel.invokeMethod('scanBluetoothSimple');
      outputPayload['BT'] = btData;
    } on PlatformException catch (e) {
      telemetryFailures.add('BT_PERMISSIONS_DENIED');
      await _logError('Bluetooth scan error', e);
    } catch (e) {
      telemetryFailures.add('BT_SCANNER_FAULT');
      await _logError('Bluetooth native scan error', e);
    }

    if (telemetryFailures.isNotEmpty) {
      outputPayload['TELEMETRY_FAILURES'] = telemetryFailures;
    }

    return outputPayload;
  }

  // WHO: Antigravity Strategy Orchestrator
  // WHY: We need to pull contextual hardware data and trigger a location save without crowding the source UI and Geolocation components. (Single Responsibility)
  // HOW: We aggregate the scan payloads, add the specific event tags (heartbeat vs manual), and pass it verbatim to the Traccar background location engine.
  static Future<void> sendTelemetry({bool isManual = false}) async {
    final Map<String, dynamic> telemetryData = await scanAll();
    final Map<String, dynamic> payload = {
      isManual ? 'manual' : 'heartbeat': true, 
      ...telemetryData
    };

    developer.log('Telemetry Injection [${isManual ? 'Manual' : 'Heartbeat'}]: ${jsonEncode(payload)}', name: 'bg.log');

    await bg.BackgroundGeolocation.getCurrentPosition(
      samples: 1, 
      persist: true, 
      extras: payload
    );
  }

  static Future<void> _logError(String label, Object error) async {
    String details;
    String? code;
    if (error is PlatformException) {
      code = error.code;
      final message = error.message ?? '';
      details = message.isNotEmpty ? message : error.toString();
    } else {
      details = error.toString();
    }

    final lowered = details.toLowerCase();
    final isPermissionError = lowered.contains('permission') || lowered.contains('denied');

    // High SNR Error Routing strictly for the UI filtering
    if (isPermissionError) {
      String userMessage;
      if (label.toLowerCase().contains('wifi')) {
        userMessage = ' [ ERROR ] USER HAS NOT AGREED TO WIFI DATA - Permission denied. Go to Android Settings > Apps > Traccar Client > Permissions > Location and select "Allow all the time"';
      } else if (label.toLowerCase().contains('bluetooth')) {
        userMessage = ' [ ERROR ] USER HAS NOT AGREED TO BLUETOOTH DATA - Permission denied. Go to Android Settings > Apps > Traccar Client > Permissions > Nearby devices and select "Allow"';
      } else {
        userMessage = ' [ ERROR ] PERMISSION DENIED - User has not granted required permissions for $label';
      }
      
      developer.log(userMessage, name: 'bg.log', error: details);
      await bg.Logger.error(userMessage);
    } else {
      final text = code != null ? ' [ ERROR ] $label ($code): $details' : ' [ ERROR ] $label: $details';
      developer.log(text, name: 'bg.log');
      await bg.Logger.error(text);
    }
  }
}
