package com.hwl.hwl_vpn

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.io.File
import java.io.RandomAccessFile

class LogStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    private var lastFileOffset: Long = 0
    private var logFile: File? = null

    private val logWatcherRunnable = object : Runnable {
        override fun run() {
            readNewLogs()
            // Schedule the next check
            handler.postDelayed(this, 500) // Check every 500ms
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        VpnLogger.log("LogStreamHandler", "👂 onListen called.")
        eventSink = events
        logFile = VpnLogger.getLogFile()
        
        // When a new listener attaches, send a clear signal and reset
        eventSink?.success("__CLEAR_LOGS__\n")
        lastFileOffset = 0
        
        // Start the periodic log checker
        handler.post(logWatcherRunnable)
    }

    override fun onCancel(arguments: Any?) {
        VpnLogger.log("LogStreamHandler", "🛑 onCancel called.")
        // Stop the periodic log checker
        handler.removeCallbacks(logWatcherRunnable)
        eventSink = null
    }

    private fun readNewLogs() {
        val file = logFile ?: return
        if (!file.exists()) return

        try {
            RandomAccessFile(file, "r").use {
                val currentSize = it.length()

                // Handle log truncation (e.g., file was cleared)
                if (currentSize < lastFileOffset) {
                    lastFileOffset = 0
                    eventSink?.success("__CLEAR_LOGS__\n")
                }

                if (currentSize > lastFileOffset) {
                    it.seek(lastFileOffset)
                    val buffer = ByteArray((currentSize - lastFileOffset).toInt())
                    it.read(buffer)
                    
                    val newLogs = String(buffer, Charsets.UTF_8)
                    // Post to main thread to ensure thread safety with eventSink
                    handler.post {
                        eventSink?.success(newLogs)
                    }
                    
                    lastFileOffset = it.filePointer
                }
            }
        } catch (e: Exception) {
            VpnLogger.log("LogStreamHandler", "❌ Error reading log file: ${e.message}")
        }
    }
}
