package org.traccar.client

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class ScannerMethodChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    
    companion object {
        const val CHANNEL_NAME = "org.traccar.client/scanner"
    }
    
    private val wifiScanner = WiFiScanner(context)
    private val btScanner = BluetoothScanner(context)
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanWiFi" -> {
                try {
                    val wifiData = wifiScanner.scanWiFiNetworks()
                    result.success(wifiData)
                } catch (e: Exception) {
                    result.error("WIFI_SCAN_ERROR", e.message, null)
                }
            }
            "scanWiFiSimple" -> {
                try {
                    val wifiData = wifiScanner.scanWiFiNetworksSimple()
                    result.success(wifiData)
                } catch (e: Exception) {
                    result.error("WIFI_SCAN_ERROR", e.message, null)
                }
            }
            "scanBluetooth" -> {
                scope.launch {
                    try {
                        val btData = btScanner.scanBluetoothDevices()
                        withContext(Dispatchers.Main) {
                            result.success(btData)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("BT_SCAN_ERROR", e.message, null)
                        }
                    }
                }
            }
            "scanBluetoothSimple" -> {
                scope.launch {
                    try {
                        val btData = btScanner.scanBluetoothDevicesSimple()
                        withContext(Dispatchers.Main) {
                            result.success(btData)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("BT_SCAN_ERROR", e.message, null)
                        }
                    }
                }
            }
            "scanAll" -> {
                scope.launch {
                    var wifiData = ""
                    var btData = ""
                    var wifiError: Exception? = null
                    var btError: Exception? = null

                    // Run WiFi scan independently
                    try {
                        wifiData = wifiScanner.scanWiFiNetworks()
                    } catch (e: Exception) {
                        wifiError = e
                    }

                    // Run Bluetooth scan independently
                    try {
                        btData = btScanner.scanBluetoothDevices()
                    } catch (e: Exception) {
                        btError = e
                    }

                    val timestamp = System.currentTimeMillis()

                    // If both failed, return error; otherwise return partial/complete data
                    if (wifiError != null && btError != null) {
                        withContext(Dispatchers.Main) {
                            result.error("SCAN_ERROR", "WiFi: ${wifiError.message}; BT: ${btError.message}", null)
                        }
                    } else {
                        val resultMap = mapOf(
                            "WIFI" to wifiData,
                            "BT" to btData,
                            "LastUpdate" to timestamp.toString()
                        )
                        withContext(Dispatchers.Main) {
                            result.success(resultMap)
                        }
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    fun dispose() {
        scope.cancel()
    }
}
