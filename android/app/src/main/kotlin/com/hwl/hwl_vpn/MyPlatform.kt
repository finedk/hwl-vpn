package com.hwl.hwl_vpn

import android.content.pm.PackageManager
import android.net.VpnService
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.NetworkInterface as LibboxNetworkInterface

class MyPlatform(private val vpnService: MyVpnService) : PlatformInterface {

    // 1. Critically important: Must return true.
    override fun usePlatformAutoDetectInterfaceControl(): Boolean {
        return true
    }

    // 2. Critically important: Protect the socket from the VPN tunnel.
    override fun autoDetectInterfaceControl(fd: Int) {
        if (!vpnService.protect(fd)) {
            throw Exception("Failed to protect socket: $fd")
        }
    }

    // 3. Critically important: Create the TUN interface.
    override fun openTun(options: TunOptions): Int {
        val builder = vpnService.Builder()
        builder.setSession("sing-box VPN")
                .setMtu(options.mtu)

        val includePackage = options.includePackage
        while (includePackage.hasNext()) {
            try {
                builder.addAllowedApplication(includePackage.next())
            } catch (e: PackageManager.NameNotFoundException) {
            }
        }

        val excludePackage = options.excludePackage
        while (excludePackage.hasNext()) {
            try {
                builder.addDisallowedApplication(excludePackage.next())
            } catch (e: PackageManager.NameNotFoundException) {
            }
        }

        val inet4AddressIterator = options.inet4Address
        while (inet4AddressIterator.hasNext()) {
            val prefix = inet4AddressIterator.next()
            builder.addAddress(prefix.address(), prefix.prefix())
        }
        val inet6Address = options.inet6Address
        while (inet6Address.hasNext()) {
            val address = inet6Address.next()
            builder.addAddress(address.address(), address.prefix())
        }

        // Manually add the default route to ensure all traffic goes through the VPN.
        builder.addRoute("0.0.0.0", 0)
        builder.addRoute("::", 0)

        //MyVpnService.dnsServer?.let { builder.addDnsServer(it) }
        builder.addDnsServer(options.dnsServerAddress.value)

        val pfd = builder.establish() ?: throw Exception("Failed to establish VPN")
        VpnLogger.log("PLATFORM", "✅ TUN interface created with fd: ${pfd.getFd()}")
        MyVpnService.vpnInterface = pfd
        return pfd.getFd()
    }

    // 4. Practically mandatory: Start monitoring the default network interface.
    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        VpnLogger.log("PLATFORM", "👀 Starting default interface monitor...")
        DefaultNetworkMonitor.start(vpnService, listener)
    }

    // 5. Practically mandatory: Stop monitoring the default network interface.
    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        VpnLogger.log("PLATFORM", "🛑 Closing default interface monitor.")
        DefaultNetworkMonitor.stop()
    }

    // 6. Practically mandatory: Get the list of system network interfaces.
    override fun getInterfaces(): NetworkInterfaceIterator {
        val interfaces = DefaultNetworkMonitor.getInterfaces(vpnService)
        return InterfaceArray(interfaces.iterator())
    }

    // --- Optional / Not implemented methods ---
    override fun writeLog(message: String) {
        VpnLogger.log("sing-box", "📦 $message")
    }

    override fun findConnectionOwner(ipProtocol: Int, sourceAddress: String, sourcePort: Int, destinationAddress: String, destinationPort: Int): Int {
        return -1 // Not implemented
    }

    override fun useProcFS(): Boolean {
        return false
    }

    override fun packageNameByUid(uid: Int): String {
        return ""
    }

    override fun uidByPackageName(packageName: String): Int {
        return -1
    }

    override fun underNetworkExtension(): Boolean {
        return false
    }

    override fun includeAllNetworks(): Boolean {
        return false
    }

    override fun clearDNSCache() {}

    override fun readWIFIState(): io.nekohasekai.libbox.WIFIState? {
        return null
    }

    override fun localDNSTransport(): io.nekohasekai.libbox.LocalDNSTransport? {
        return null
    }

    override fun systemCertificates(): io.nekohasekai.libbox.StringIterator? {
        return null
    }

    override fun sendNotification(notification: io.nekohasekai.libbox.Notification) {}

    private class InterfaceArray(private val iterator: Iterator<LibboxNetworkInterface>) :
        NetworkInterfaceIterator {

        override fun hasNext(): Boolean {
            return iterator.hasNext()
        }

        override fun next(): LibboxNetworkInterface {
            return iterator.next()
        }
    }
}
