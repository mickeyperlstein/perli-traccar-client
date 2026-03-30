package org.traccar.client

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.Manifest
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*

class BluetoothScanner(private val context: Context) {
    
    private val scannedDevices = mutableListOf<ScanResult>()
    
    /**
     * Scans for nearby Bluetooth devices and returns formatted string
     * Format: Name:MAC:RSSI:TxPower,Name:MAC:RSSI:TxPower,...
     */
    suspend fun scanBluetoothDevices(): String = withContext(Dispatchers.IO) {
        ensureBluetoothPermission()

        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            ?: throw IllegalStateException("BluetoothManager unavailable")
        val bluetoothAdapter = bluetoothManager.adapter
            ?: throw IllegalStateException("BluetoothAdapter unavailable")

        if (!bluetoothAdapter.isEnabled) {
            throw IllegalStateException("Bluetooth is disabled")
        }

        scannedDevices.clear()

        val scanner = bluetoothAdapter.bluetoothLeScanner
            ?: throw IllegalStateException("BluetoothLeScanner unavailable")

        val scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                scannedDevices.add(result)
            }

            override fun onBatchScanResults(results: List<ScanResult>) {
                scannedDevices.addAll(results)
            }

            override fun onScanFailed(errorCode: Int) {
                throw RuntimeException("Bluetooth scan failed with code $errorCode")
            }
        }

        scanner.startScan(scanCallback)

        delay(5000)

        scanner.stopScan(scanCallback)

        return@withContext scannedDevices
            .distinctBy { it.device.address }
            .sortedByDescending { it.rssi }
            .take(10)
            .joinToString(",") {
                val name = sanitizeName(it.device.name ?: "Unknown")
                val mac = it.device.address
                val rssi = it.rssi
                val txPower = it.txPower
                "$name:$mac:$rssi:$txPower"
            }
    }
    
    /**
     * Simple format with just device name and signal strength
     * Format: Name:RSSI,Name:RSSI,...
     */
    suspend fun scanBluetoothDevicesSimple(): String = withContext(Dispatchers.IO) {
        ensureBluetoothPermission()

        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            ?: throw IllegalStateException("BluetoothManager unavailable")
        val bluetoothAdapter = bluetoothManager.adapter
            ?: throw IllegalStateException("BluetoothAdapter unavailable")

        if (!bluetoothAdapter.isEnabled) {
            throw IllegalStateException("Bluetooth is disabled")
        }

        scannedDevices.clear()

        val scanner = bluetoothAdapter.bluetoothLeScanner
            ?: throw IllegalStateException("BluetoothLeScanner unavailable")

        val scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                scannedDevices.add(result)
            }

            override fun onBatchScanResults(results: List<ScanResult>) {
                scannedDevices.addAll(results)
            }

            override fun onScanFailed(errorCode: Int) {
                throw RuntimeException("Bluetooth scan failed with code $errorCode")
            }
        }

        scanner.startScan(scanCallback)
        delay(5000)
        scanner.stopScan(scanCallback)

        return@withContext scannedDevices
            .distinctBy { it.device.address }
            .sortedByDescending { it.rssi }
            .take(10)
            .joinToString(",") {
                val name = sanitizeName(it.device.name ?: it.device.address)
                "${name}:${it.rssi}"
            }
    }

    private fun ensureBluetoothPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_SCAN
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                throw SecurityException("USER HAS NOT AGREED TO BLUETOOTH DATA - BLUETOOTH_SCAN permission not granted. Go to Android Settings > Apps > Traccar Client > Permissions > Nearby devices and select 'Allow'")
            }
        } else {
            if (ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                throw SecurityException("USER HAS NOT AGREED TO BLUETOOTH DATA - ACCESS_FINE_LOCATION permission not granted. Android requires Location permission to scan Bluetooth devices.")
            }
        }
    }
    
    /**
     * Remove special characters from device name
     */
    private fun sanitizeName(name: String): String {
        return name.replace(",", "_").replace(":", "_")
    }
}
