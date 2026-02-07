package com.hwl.hwl_vpn

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.io.ByteArrayOutputStream
import java.net.NetworkInterface
import java.util.Collections
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hwl_vpn.app/channel"
    private val LOG_CHANNEL = "com.hwl.hwl-vpn/logs"
    private lateinit var channel: MethodChannel
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 99
    private val VPN_PERMISSION_REQUEST_CODE = 1

    private val tileReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                "TOGGLE_VPN" -> {
                    val serviceIntent = Intent(this@MainActivity, MyVpnService::class.java).apply {
                        action = MyVpnService.ACTION_TOGGLE_VPN
                    }
                    startService(serviceIntent)
                }
                "REQUEST_STATUS" -> {
                    requestVpnStatus()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        VpnLogger.initialize(this)
        VpnLogger.clear()
        VpnLogger.log("MAIN_ACTIVITY", "🚀 MainActivity onCreate. Logs cleared.")
        requestNotificationPermission()
        val filter = IntentFilter()
        filter.addAction("TOGGLE_VPN")
        filter.addAction("REQUEST_STATUS")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(tileReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(tileReceiver, filter)
        }
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            return
        }
        if (intent.getBooleanExtra("REQUEST_VPN_PERMISSION", false)) {
            val vpnIntent = VpnService.prepare(this)
            if (vpnIntent != null) {
                startActivityForResult(vpnIntent, VPN_PERMISSION_REQUEST_CODE)
            } else {
                onActivityResult(VPN_PERMISSION_REQUEST_CODE, Activity.RESULT_OK, null)
            }
            intent.removeExtra("REQUEST_VPN_PERMISSION")
            return
        }

        if (intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_LAUNCHER)) {
            val prefs = getSharedPreferences("vpn_settings", Context.MODE_PRIVATE)
            if (prefs.getBoolean("persistentNotification", false)) {
                val serviceIntent = Intent(this, MyVpnService::class.java).apply {
                    action = MyVpnService.ACTION_SET_PERSISTENT
                    putExtra("enabled", true)
                }
                startService(serviceIntent)
            }
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_PERMISSION_REQUEST_CODE)
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup Log Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LOG_CHANNEL).setStreamHandler(LogStreamHandler(this))
        VpnLogger.log("MAIN_ACTIVITY", "✅ Log channel configured.")

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val showSystemApps = call.argument<Boolean>("showSystemApps") ?: false
                    result.success(getInstalledApps(showSystemApps))
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.error("INVALID_ARGUMENT", "Package name cannot be null", null)
                    } else {
                        result.success(getAppIcon(packageName))
                    }
                }
                "startService" -> {
                    val config = call.argument<String>("config")
                    val dns = call.argument<String>("dns")
                    val disableMemoryLimit = call.argument<Boolean>("disableMemoryLimit")
                    val persistentNotification = call.argument<Boolean>("persistentNotification")
                    val perAppProxyEnabled = call.argument<Boolean>("perAppProxyEnabled") ?: false
                    val perAppProxyMode = call.argument<String>("perAppProxyMode")
                    val perAppProxyList = call.argument<List<String>>("perAppProxyList")

                    val prefs = getSharedPreferences("vpn_settings", Context.MODE_PRIVATE)
                    with(prefs.edit()) {
                        putString("config", config)
                        putString("dns", dns)
                        putBoolean("disableMemoryLimit", disableMemoryLimit ?: true)
                        putBoolean("persistentNotification", persistentNotification ?: false)
                        putBoolean("perAppProxyEnabled", perAppProxyEnabled)
                        putString("perAppProxyMode", perAppProxyMode)
                        putStringSet("perAppProxyList", perAppProxyList?.toSet())
                        apply()
                    }

                    MyVpnService.config = config
                    MyVpnService.dnsServer = dns
                    if (disableMemoryLimit != null) {
                        MyVpnService.disableMemoryLimit = disableMemoryLimit
                    }
                    if (persistentNotification != null) {
                        MyVpnService.persistentNotification = persistentNotification
                    }
                    MyVpnService.perAppProxyEnabled = perAppProxyEnabled
                    MyVpnService.perAppProxyMode = perAppProxyMode
                    MyVpnService.perAppProxyList = perAppProxyList

                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, VPN_PERMISSION_REQUEST_CODE)
                    } else {
                        onActivityResult(VPN_PERMISSION_REQUEST_CODE, Activity.RESULT_OK, null)
                    }
                    result.success(null)
                }
                "stopService" -> {
                    Log.d("MainActivity", "Received stopService call from Flutter, sending STOP action")
                    val intent = Intent(this, MyVpnService::class.java).apply {
                        action = MyVpnService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(null)
                }
                "setPersistentNotification" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val intent = Intent(this, MyVpnService::class.java).apply {
                        action = MyVpnService.ACTION_SET_PERSISTENT
                        putExtra("enabled", enabled)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "getWifiIpAddress" -> {
                    result.success(getWifiIpAddress())
                }
                "isWifiConnected" -> {
                    result.success(isWifiConnected())
                }
                else -> result.notImplemented()
            }
        }
        MyVpnService.mainActivity = this
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(tileReceiver)
        if (MyVpnService.mainActivity === this) {
            MyVpnService.mainActivity = null
        }
    }

    private fun getInstalledApps(showSystemApps: Boolean): List<Map<String, Any?>> {
        val pm = packageManager
        val apps = pm.getInstalledApplications(0)
        val appList = mutableListOf<Map<String, Any?>>()

        for (app in apps) {
            if (app.packageName == "com.hwl.hwl_vpn") {
                continue
            }
            if (!showSystemApps && (app.flags and ApplicationInfo.FLAG_SYSTEM != 0)) {
                continue
            }
            val appInfo = mapOf(
                    "name" to app.loadLabel(pm).toString(),
                    "packageName" to app.packageName
            )
            appList.add(appInfo)
        }
        return appList
    }

    private fun getAppIcon(packageName: String): ByteArray? {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            drawableToByteArray(drawable)
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

    private fun drawableToByteArray(drawable: Drawable?): ByteArray? {
        if (drawable == null) return null
        val bitmap = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_PERMISSION_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            val intent = Intent(this, MyVpnService::class.java).apply {
                action = MyVpnService.ACTION_START
            }
            startService(intent)
        }
    }

    override fun onResume() {
        super.onResume()
        requestVpnStatus()
    }

    private fun requestVpnStatus() {
        val intent = Intent(this, MyVpnService::class.java).apply {
            action = MyVpnService.ACTION_REQUEST_STATUS
        }
        startService(intent)
    }

    fun updateStatus(status: String) {
        if (isFinishing || isDestroyed) {
            return
        }
        runOnUiThread {
            channel.invokeMethod("updateStatus", status)
        }
    }

    private fun getWifiIpAddress(): String? {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork ?: return null
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return null

        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
            val linkProperties = connectivityManager.getLinkProperties(network) ?: return null
            for (linkAddress in linkProperties.linkAddresses) {
                val address = linkAddress.address
                if (address is java.net.Inet4Address) {
                    return address.hostAddress
                }
            }
        }
        return null
    }

    private fun isWifiConnected(): Boolean {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }
}
