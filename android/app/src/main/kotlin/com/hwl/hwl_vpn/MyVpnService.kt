package com.hwl.hwl_vpn

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import io.nekohasekai.libbox.BoxService
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.SetupOptions
import java.io.File

class MyVpnService : VpnService() {

    private fun saveState() {
        val prefs = getSharedPreferences("vpn_status", Context.MODE_PRIVATE)
        with(prefs.edit()) {
            putBoolean("isRunning", isRunning)
            apply()
        }
    }

    private var box: BoxService? = null

    override fun onCreate() {
        super.onCreate()
        VpnLogger.initialize(this)
        VpnLogger.log("VPN_SERVICE", "🚀 MyVpnService onCreate")
        startAsForeground() // ОБЯЗАТЕЛЬНО сразу
    }

    companion object {
        var isRunning = false
        var isConnecting = false
        var mainActivity: MainActivity? = null
        var config: String? = null
        var dnsServer: String? = null
        var vpnInterface: ParcelFileDescriptor? = null
        var disableMemoryLimit: Boolean = true
        var persistentNotification: Boolean = false
        var perAppProxyEnabled: Boolean = false
        var perAppProxyMode: String? = null
        var perAppProxyList: List<String>? = null

        const val ACTION_START = "START"
        const val ACTION_STOP = "STOP"
        const val ACTION_SHUTDOWN = "SHUTDOWN"
        const val ACTION_SET_PERSISTENT = "SET_PERSISTENT"
        const val ACTION_TOGGLE_VPN = "TOGGLE_VPN"
        const val ACTION_REQUEST_STATUS = "REQUEST_STATUS"
        const val ACTION_VPN_STATUS = "VPN_STATUS"
        const val NOTIFICATION_CHANNEL_ID = "vpn_service_channel"
    }

    private fun broadcastStatus() {
        val intent = Intent(ACTION_VPN_STATUS)
        intent.putExtra("isRunning", isRunning)
        sendBroadcast(intent)
    }

    private fun startAsForeground() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("HWL VPN")
            .setContentText("Service is running")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .build()

        try {
            startForeground(1, notification)
        } catch (e: Exception) {
            VpnLogger.log("VPN_SERVICE", "❌ startForeground failed in startAsForeground: ${e.message}")
            e.printStackTrace()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Гарантия foreground даже если Android перезапустил сервис
        startAsForeground()

        when (intent?.action) {
            ACTION_TOGGLE_VPN -> {
                if (isRunning) {
                    stopVpnInternal()
                } else if (!isConnecting) {
                    startVpn()
                }
            }

            ACTION_START -> {
                if (!isRunning && !isConnecting) startVpn()
            }

            ACTION_STOP -> {
                if (isRunning) stopVpnInternal() else shutdown()
            }

            ACTION_REQUEST_STATUS -> {
                broadcastStatus()
                updateNotification()
                mainActivity?.updateStatus(if (isRunning) "Started" else "Stopped")
            }

            ACTION_SET_PERSISTENT -> {
                persistentNotification = intent.getBooleanExtra("enabled", false)
                getSharedPreferences("vpn_settings", Context.MODE_PRIVATE)
                    .edit().putBoolean("persistentNotification", persistentNotification).apply()
                updateNotification()
            }
        }

        return START_STICKY
    }

    private fun loadSettings() {
        val prefs = getSharedPreferences("vpn_settings", Context.MODE_PRIVATE)
        config = prefs.getString("config", null)
        dnsServer = prefs.getString("dns", null)
        disableMemoryLimit = prefs.getBoolean("disableMemoryLimit", true)
        persistentNotification = prefs.getBoolean("persistentNotification", false)
        perAppProxyEnabled = prefs.getBoolean("perAppProxyEnabled", false)
        perAppProxyMode = prefs.getString("perAppProxyMode", "Include")
        perAppProxyList = prefs.getStringSet("perAppProxyList", null)?.toList()
    }

    private fun startVpn() {
        if (isRunning || isConnecting) return

        isConnecting = true
        updateNotification()

        VpnLogger.clear()
        VpnLogger.log("VPN_SERVICE", "🚀 startVpn called.")

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val savedTimestamp = prefs.getLong("flutter.serverCacheTimestamp", 0)

        if (savedTimestamp == 0L) {
            val errorMessage = "Error: No cache timestamp found. Please open the app to connect at least once."
            stopVpnDueToError(errorMessage)
            return
        }

        val sevenDaysInMillis = 604800000L
        val currentTimestamp = System.currentTimeMillis()

        if ((currentTimestamp - savedTimestamp > sevenDaysInMillis)) {
            val errorMessage = "Error: VPN configuration expired. Please open the app to refresh."
            stopVpnDueToError(errorMessage)
            return
        }
        VpnLogger.log("VPN_SERVICE", "✅ Cache timestamp is valid (Saved: $savedTimestamp, Current: $currentTimestamp).")

        loadSettings()

        if (config == null) {
            val errorMessage = "Error: Config not found"
            stopVpnDueToError(errorMessage)
            return
        }

        Thread {
            try {
                VpnLogger.log("VPN_SERVICE", "🧵 Starting VPN connection thread.")
                val platform = MyPlatform(this)
                val workingDir = File(filesDir, "singbox")
                if (!workingDir.exists()) workingDir.mkdirs()
                val tempDir = File(cacheDir, "singbox")
                if (!tempDir.exists()) tempDir.mkdirs()

                val options = SetupOptions()
                options.basePath = workingDir.absolutePath
                options.workingPath = workingDir.absolutePath
                options.tempPath = tempDir.absolutePath
                options.fixAndroidStack = true
                VpnLogger.log("VPN_SERVICE", "🔧 Setting up Libbox...")
                Libbox.setup(options)
                VpnLogger.log("VPN_SERVICE", "Libbox setup complete. Memory limit disabled: $disableMemoryLimit")
                Libbox.setMemoryLimit(!disableMemoryLimit)

                VpnLogger.log("VPN_SERVICE", "Creating new sing-box service...")
                box = Libbox.newService(config, platform)
                VpnLogger.log("VPN_SERVICE", "Service created, starting...")
                box?.start()

                isConnecting = false
                isRunning = true
                saveState()
                mainActivity?.updateStatus("Started")
                VpnLogger.log("VPN_SERVICE", "✅ VPN connection established successfully.")
                updateNotification()
                broadcastStatus()
            } catch (e: Exception) {
                e.printStackTrace()
                stopVpnDueToError("Error: ${e.message}")
            }
        }.start()
    }

    private fun stopVpnDueToError(errorMessage: String) {
        VpnLogger.log("VPN_SERVICE", "❌ VPN startup/connection failed: $errorMessage")
        mainActivity?.updateStatus(errorMessage)
        isConnecting = false
        isRunning = false
        updateNotification()
        stopVpnResources()
    }

    private fun stopVpnResources() {
        VpnLogger.log("VPN_SERVICE", "🛑 Stopping VPN resources...")
        try {
            vpnInterface?.close()
            vpnInterface = null
            VpnLogger.log("VPN_SERVICE", "✅ VPN interface closed.")
        } catch (e: Exception) {
            VpnLogger.log("VPN_SERVICE", "❌ Error closing VPN interface: ${e.message}")
            e.printStackTrace()
        }
        box?.close()
        box = null
        VpnLogger.log("VPN_SERVICE", "Sing-box service closed.")
        if (isRunning || isConnecting) {
            mainActivity?.updateStatus("Stopped")
        }
        // Always update state and notify listeners to ensure consistency.
        isRunning = false
        isConnecting = false
        saveState()
        broadcastStatus()
        VpnLogger.log("VPN_SERVICE", "✅ VPN status updated to stopped.")
    }

    private fun stopVpnInternal() {
        if (!isRunning) return
        stopVpnResources()
        if (persistentNotification) {
            updateNotification()
        } else {
            shutdown()
        }
    }

    private fun shutdown() {
        VpnLogger.log("VPN_SERVICE", "🛑 Service shutting down.")
        stopVpnResources()
        stopForeground(true)
        stopSelf()
    }

    private fun updateNotification() {
        val toggleVpnIntent = Intent(this, MyVpnService::class.java).apply {
            action = ACTION_TOGGLE_VPN
        }
        val toggleVpnPendingIntent = PendingIntent.getService(this, 0, toggleVpnIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("HWL VPN")
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .setOngoing(isRunning || isConnecting || persistentNotification)
            .setShowWhen(false)
            .setSound(null)
            .setContentIntent(toggleVpnPendingIntent)

        if (isConnecting) {
            builder.setContentText("Подключение...")
        } else if (isRunning) {
            builder.setContentText("нажмите, чтобы выключить")
        } else {
            builder.setContentText("нажмите, чтобы включить впн")
        }

        // We must call startForeground to update the notification.
        // If the service is not supposed to be ongoing, we stop it right after.
        try {
            startForeground(1, builder.build())
        } catch (e: Exception) {
            VpnLogger.log("VPN_SERVICE", "❌ startForeground failed in updateNotification: ${e.message}")
            e.printStackTrace()
        }
        
        if (!isRunning && !isConnecting && !persistentNotification) {
            stopForeground(true)
        }
    }

    override fun onDestroy() {
        Log.d("MyVpnService", "onDestroy called")
        stopVpnResources()
        super.onDestroy()
    }

    // This method is no longer needed as the channel is created in startAsForeground
    // but we keep it for updateNotification to be safe, ensuring it uses the same ID.
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}