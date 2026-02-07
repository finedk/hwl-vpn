package com.hwl.hwl_vpn

import android.content.Context
import android.util.Log
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object VpnLogger {
    private const val LOG_FILE_NAME = "vpn_debug.log"
    private var logFile: File? = null

    fun initialize(context: Context) {
        if (logFile == null) {
            logFile = File(context.filesDir, LOG_FILE_NAME)
        }
    }

    fun getLogFile(): File? {
        return logFile
    }

    fun log(tag: String, message: String) {
        // Log to logcat as well for easier debugging with adb
        Log.d(tag, message)

        val file = logFile ?: return
        try {
            // ISO 8601 format with timezone, similar to Swift's withInternetDateTime
            val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.US)
            val timestamp = formatter.format(Date())
            
            val logMessage = "$timestamp [$tag]: $message\n"
            file.appendText(logMessage)
        } catch (e: IOException) {
            Log.e("VpnLogger", "Failed to write to log file", e)
        }
    }

    fun clear() {
        val file = logFile ?: return
        try {
            if (file.exists()) {
                file.writeText("")
            }
        } catch (e: IOException) {
            Log.e("VpnLogger", "Failed to clear log file", e)
        }
    }
}
