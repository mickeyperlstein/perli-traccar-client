package org.traccar.client

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var scannerChannel: ScannerMethodChannel? = null

    // WHO: Automated Strategy Generator (Antigravity)
    // WHY: We need an isolated Native bridge to spawn Android Location/Bluetooth Scanner APIs without polluting the Flutter UI thread.
    // HOW: By injecting a standalone `ScannerMethodChannel` listener into the core `configureFlutterEngine` pipeline, we intercept Dart 'scanAll' invokes instantly.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        scannerChannel = ScannerMethodChannel(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ScannerMethodChannel.CHANNEL_NAME)
            .setMethodCallHandler(scannerChannel)
    }

    override fun onDestroy() {
        super.onDestroy()
        scannerChannel?.dispose()
    }
}
