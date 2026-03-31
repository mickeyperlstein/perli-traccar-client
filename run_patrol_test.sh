#!/bin/bash
# Automated Patrol Test Runner with Cleanup
# Stops any running app instances before running tests

set -e

DEVICE="${1:-emulator-5554}"
TEST_TARGET="${2:-integration_test/scanner_test.dart}"
APP_ID="${3:-org.traccar.client}"

echo "=== Patrol Test Runner ==="
echo "Device: $DEVICE"
echo "Test: $TEST_TARGET"
echo "App ID: $APP_ID"

# Check and stop existing app
echo "Checking for running app..."
if adb -s "$DEVICE" shell pidof "$APP_ID" > /dev/null 2>&1; then
    echo "App is running. Stopping..."
    adb -s "$DEVICE" shell am force-stop "$APP_ID"
    sleep 2
    echo "App stopped."
else
    echo "App not running."
fi

# Pre-grant Android runtime permissions that commonly block Patrol.
echo "Granting runtime permissions (if supported by device/API level)..."
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS > /dev/null 2>&1 || true
echo "Permission pre-grant complete."

# Build and run via patrol CLI
echo "Building and running via patrol..."
cd /Users/mickeyperlstein/Documents/perli/FE/traccar_client

# Export patrol server ports
export PATROL_TEST_SERVER_PORT=8085
export PATROL_APP_SERVER_PORT=8086

# Pre-generate test bundle to fix paths
patrol build --target "$TEST_TARGET" --device "$DEVICE" 2>/dev/null || true

# Fix test bundle if it has broken imports
if [ -f patrol_test/test_bundle.dart ]; then
    echo "Fixing test bundle imports..."
    # Fix absolute paths to relative
    sed -i '' "s|import 'Users/.*integration_test/scanner_test.dart' as .*;|import '../integration_test/scanner_test.dart' as scanner_test;|" patrol_test/test_bundle.dart
    sed -i '' "s|group('Users.*integration_test.scanner_test', .*main);|group('scanner_test', scanner_test.main);|" patrol_test/test_bundle.dart
fi

# Remove incorrectly named folder if patrol created it
if [ -d "/Users/mickeyperlstein/Documents/perli/FE/traccar-client" ]; then
    echo "Removing incorrectly named folder..."
    rm -rf "/Users/mickeyperlstein/Documents/perli/FE/traccar-client"
fi

patrol test --target "$TEST_TARGET" --device "$DEVICE"

echo "=== Test Complete ==="
