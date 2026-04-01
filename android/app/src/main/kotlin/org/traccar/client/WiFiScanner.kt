package org.traccar.client

import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.Manifest
import androidx.core.content.ContextCompat

class WiFiScanner(private val context: Context) {
    
    /**
     * Scans for nearby WiFi networks and returns formatted string
     * Format: SSID:BSSID:RSSI:FREQ,SSID:BSSID:RSSI:FREQ,...
     */
    fun scanWiFiNetworks(): String {
        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            throw SecurityException("USER HAS NOT AGREED TO WIFI DATA - ACCESS_FINE_LOCATION permission not granted. Android requires Location permission to scan WiFi networks.")
        }

        val wifiManager = context.applicationContext
            .getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: throw IllegalStateException("WifiManager unavailable")

        wifiManager.startScan()
        val scanResults = wifiManager.scanResults

        return scanResults
            .filter { it.SSID.isNotEmpty() }
            .sortedByDescending { it.level }
            .take(10)
            .joinToString(",") {
                "${sanitizeSSID(it.SSID)}:${it.BSSID}:${it.level}:${it.frequency}"
            }
    }
    
    /**
     * Simple format with just SSID and signal strength
     * Format: SSID:RSSI,SSID:RSSI,...
     */
    fun scanWiFiNetworksSimple(): String {
        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            throw SecurityException("ACCESS_FINE_LOCATION permission not granted for WiFi scanning")
        }

        val wifiManager = context.applicationContext
            .getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: throw IllegalStateException("WifiManager unavailable")

        wifiManager.startScan()
        val scanResults = wifiManager.scanResults

        return scanResults
            .filter { it.SSID.isNotEmpty() }
            .sortedByDescending { it.level }
            .take(10)
            .joinToString(",") {
                "${sanitizeSSID(it.SSID)}:${it.level}"
            }
    }
    
    /**
     * Remove quotes and special characters from SSID
     */
    private fun sanitizeSSID(ssid: String): String {
        return ssid.replace("\"", "").replace(",", "_").replace(":", "_")
    }
}
