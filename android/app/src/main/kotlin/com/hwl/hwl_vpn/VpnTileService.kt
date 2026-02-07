package com.hwl.hwl_vpn

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.net.VpnService
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.widget.Toast
import androidx.annotation.RequiresApi

 @RequiresApi(Build.VERSION_CODES.N)
class VpnTileService : TileService() {

    private var isRunning = false

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == MyVpnService.ACTION_VPN_STATUS) {
                isRunning = intent.getBooleanExtra("isRunning", false)
                updateTile()
            }
        }
    }

    override fun onStartListening() {
        super.onStartListening()

        // Read persisted state first for immediate UI update
        val prefs = getSharedPreferences("vpn_status", Context.MODE_PRIVATE)
        isRunning = prefs.getBoolean("isRunning", false)
        updateTile()

        // Then register for live updates
        val filter = IntentFilter(MyVpnService.ACTION_VPN_STATUS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(statusReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(statusReceiver, filter)
        }
        // Request fresh status from service just in case it's alive and can provide a more accurate state
        sendBroadcast(Intent(MyVpnService.ACTION_REQUEST_STATUS))
    }

    override fun onStopListening() {
        super.onStopListening()
        try {
            unregisterReceiver(statusReceiver)
        } catch (e: Exception) {
            // Игнорируем, если не был зарегистрирован
        }
    }

    override fun onClick() {
        super.onClick()

        // 1. Проверяем, есть ли права на VPN
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent != null) {
            // Если права не даны, мы НЕ МОЖЕМ запустить сервис из фона.
            // Нужно открыть активити, чтобы запросить права.
            try {
                val intent = Intent(this, MainActivity::class.java)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivityAndCollapse(intent)
                Toast.makeText(this, "Please allow VPN permission inside the app first", Toast.LENGTH_LONG).show()
            } catch (e: Exception) {
                e.printStackTrace()
            }
            return
        }

        // 2. Логика переключения
        val intent = Intent(this, MyVpnService::class.java)
        if (isRunning) {
            intent.action = MyVpnService.ACTION_STOP
            startService(intent) // Для остановки достаточно startService
        } else {
            intent.action = MyVpnService.ACTION_START
            // Для Android 8+ (Oreo) нужен startForegroundService
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
    }

    private fun updateTile() {
        val tile = qsTile ?: return
        tile.icon = Icon.createWithResource(this, R.drawable.ic_notification)
        
        tile.label = if (isRunning) "VPN On" else "VPN Off"
        tile.state = if (isRunning) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.updateTile()
    }
}