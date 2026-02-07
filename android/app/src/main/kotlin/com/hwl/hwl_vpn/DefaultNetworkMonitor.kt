package com.hwl.hwl_vpn

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Handler
import android.os.Looper
import io.nekohasekai.libbox.InterfaceUpdateListener
import java.net.NetworkInterface

object DefaultNetworkMonitor {
    private var listener: InterfaceUpdateListener? = null
    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun start(context: Context, listener: InterfaceUpdateListener) {
        this.listener = listener
        this.connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                updateDefaultInterface(network)
            }

            override fun onLost(network: Network) {
                updateDefaultInterface(null)
            }
        }
        connectivityManager?.registerNetworkCallback(request, networkCallback!!, mainHandler)

        // Initial check
        updateDefaultInterface(connectivityManager?.activeNetwork)
    }

    fun stop() {
        networkCallback?.let { connectivityManager?.unregisterNetworkCallback(it) }
        listener = null
        connectivityManager = null
        networkCallback = null
    }

    private fun updateDefaultInterface(network: Network?) {
        val currentListener = listener ?: return
        if (network != null) {
            val linkProperties = connectivityManager?.getLinkProperties(network) ?: return
            val interfaceName = linkProperties.interfaceName ?: return
            try {
                val networkInterface = NetworkInterface.getByName(interfaceName)
                if (networkInterface != null) {
                    currentListener.updateDefaultInterface(interfaceName, networkInterface.index, false, false)
                }
            } catch (e: Exception) {
                // Ignore
            }
        } else {
            currentListener.updateDefaultInterface("", -1, false, false)
        }
    }

    fun getInterfaces(context: Context): List<io.nekohasekai.libbox.NetworkInterface> {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val networks = connectivityManager.allNetworks
        val systemInterfaces = NetworkInterface.getNetworkInterfaces().toList()
        val interfaces = mutableListOf<io.nekohasekai.libbox.NetworkInterface>()

        for (network in networks) {
            val linkProperties = connectivityManager.getLinkProperties(network) ?: continue
            val caps = connectivityManager.getNetworkCapabilities(network) ?: continue
            val interfaceName = linkProperties.interfaceName ?: continue
            val systemInterface = systemInterfaces.find { it.name == interfaceName } ?: continue

            val boxInterface = io.nekohasekai.libbox.NetworkInterface()
            boxInterface.name = interfaceName
            boxInterface.index = systemInterface.index
            boxInterface.mtu = systemInterface.mtu
            // You might need to implement a StringIterator for addresses and DNS servers
            // For simplicity, leaving them empty for now.
            interfaces.add(boxInterface)
        }
        return interfaces
    }
}
