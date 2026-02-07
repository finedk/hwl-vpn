import Cocoa
import FlutterMacOS
import NetworkExtension
import Network

// Стример для отправки логов в Flutter (скопировано из iOS)
class LogStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    func sendLog(_ log: String) {
        // Добавляем перенос строки, чтобы каждый лог был на новой строке в консоли Flutter
        eventSink?(log + "\n")
    }
}

// Стример для отправки статуса VPN в Flutter (скопировано из iOS)
class VpnStatusStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // На macOS делегат может быть еще не готов, вызываем из MainFlutterWindow
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.loadManagerAndSendStatus()
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    func sendStatus(_ status: String) {
        eventSink?(status)
    }
}


@main
class AppDelegate: FlutterAppDelegate {
    
    // ВАЖНО: Убедитесь, что этот Bundle ID совпадает с Bundle ID вашего Tunnel таргета
    let tunnelBundleId = "com.hwl.hwl-vpn.Tunnel"
    let appGroupId = "group.com.hwl.hwlVpn" // Ваш App Group
    var logTimer: Timer?
    var lastFileOffset: UInt64 = 0
    let logStreamHandler = LogStreamHandler()
    let vpnStatusStreamHandler = VpnStatusStreamHandler()

    

    override func applicationDidFinishLaunching(_ notification: Notification) {
        super.applicationDidFinishLaunching(notification)
        // Вся логика инициализации теперь в MainFlutterWindow.swift
    }
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
      return true
    }

    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    
    // --- Методы-хелперы остаются здесь ---
    
    func setupFlutterChannels(controller: FlutterViewController) {
        // Канал для управления VPN (имя из ошибки)
        let vpnChannel = FlutterMethodChannel(name: "com.hwl_vpn.app/channel",
                                              binaryMessenger: controller.engine.binaryMessenger)
        
        // Канал для стриминга логов (имя из ошибки)
        let logChannel = FlutterEventChannel(name: "com.hwl.hwl-vpn/logs",
                                             binaryMessenger: controller.engine.binaryMessenger)
        logChannel.setStreamHandler(logStreamHandler)

        // Канал для статуса VPN (имя как у логов)
        let vpnStatusChannel = FlutterEventChannel(name: "com.hwl.hwl-vpn/status",
                                             binaryMessenger: controller.engine.binaryMessenger)
        vpnStatusChannel.setStreamHandler(vpnStatusStreamHandler)
        
        vpnChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            if call.method == "startService" {
                self.logStreamHandler.sendLog("🚀 [APP_DELEGATE_MACOS] Received 'startService' call from Flutter.")
                guard let args = call.arguments as? [String: Any],
                      let config = args["config"] as? String else {
                    let errorMessage = "Missing 'config' argument in 'startService' call"
                    self.logStreamHandler.sendLog("❌ [APP_DELEGATE_MACOS] \(errorMessage)")
                    result(FlutterError(code: "INVALID_ARG", message: errorMessage, details: nil))
                    return
                }
                let disableMemoryLimit = args["disableMemoryLimit"] as? Bool ?? false
                self.setupAndStartVPN(config: config, disableMemoryLimit: disableMemoryLimit, result: result)
            } else if call.method == "disconnect" {
                self.logStreamHandler.sendLog("🛑 [APP_DELEGATE_MACOS] Received 'disconnect' call from Flutter.")
                self.disconnectVPN(result: result)
            } else if call.method == "getIpAddress" {
                result(self.getIPAddress())
            } else if call.method == "isWifiConnected" {
                self.isWifiConnected(result: result)
            } else if call.method == "saveCacheTimestamp" {
                self.logStreamHandler.sendLog("💾 [APP_DELEGATE_MACOS] Received 'saveCacheTimestamp' call.")
                guard let args = call.arguments as? [String: Any],
                      let timestamp = args["timestamp"] as? Int else {
                    let errorMessage = "Missing 'timestamp' argument in 'saveCacheTimestamp' call"
                    self.logStreamHandler.sendLog("❌ [APP_DELEGATE_MACOS] \(errorMessage)")
                    result(FlutterError(code: "INVALID_ARG", message: errorMessage, details: nil))
                    return
                }
                let userDefaults = UserDefaults(suiteName: self.appGroupId)
                userDefaults?.set(timestamp, forKey: "cacheTimestamp")
                result(nil)
            } else {
                self.logStreamHandler.sendLog("⚠️ [APP_DELEGATE_MACOS] Unimplemented method: \(call.method)")
                result(FlutterMethodNotImplemented)
            }
        })
    }

    func clearLogFile() {
        guard let fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("tunnel_debug.log") else { return }
        
        try? FileManager.default.removeItem(at: fileURL)
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        lastFileOffset = 0
        logStreamHandler.sendLog("🌀 [APP_DELEGATE_MACOS] Log file cleared.")
    }
    
    func startLogWatcher() {
        logTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.readNewLogs()
        }
        logStreamHandler.sendLog("👀 [APP_DELEGATE_MACOS] Log watcher started.")
    }
    
    func readNewLogs() {
        guard let fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("tunnel_debug.log") else { return }
        
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return }
        
        defer { try? fileHandle.close() }

        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        let currentSize = attributes?[.size] as? UInt64 ?? 0

        if currentSize < lastFileOffset {
            lastFileOffset = 0
            self.logStreamHandler.sendLog("__CLEAR_LOGS__\n")
        }
        
        fileHandle.seek(toFileOffset: lastFileOffset)
        
        let data = fileHandle.readDataToEndOfFile()
        if !data.isEmpty {
            lastFileOffset = fileHandle.offsetInFile
            if let string = String(data: data, encoding: .utf8) {
                self.logStreamHandler.sendLog(string)
            }
        }
    }

    @objc func vpnStatusDidChange(_ notification: Notification) {
        guard let connection = notification.object as? NEVPNConnection else { return }
        let status = connection.status
        logStreamHandler.sendLog("ℹ️ [APP_DELEGATE_MACOS] VPN status changed: \(statusToString(status))")
        vpnStatusStreamHandler.sendStatus(statusToString(status))
    }
    
    private func statusToString(_ status: NEVPNStatus) -> String {
        switch status {
        case .disconnected: return "disconnected"
        case .invalid: return "invalid"
        case .connected: return "connected"
        case .connecting: return "connecting"
        case .disconnecting: return "disconnecting"
        case .reasserting: return "reasserting"
        @unknown default: return "unknown"
        }
    }

    func getIPAddress() -> String {
        var address: String = "0.0.0.0" // Default to 0.0.0.0 as requested
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return address }
        guard let firstAddr = ifaddr else { return address }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            // Check if interface is UP, RUNNING, and not LOOPBACK
            if (flags & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK)) == (IFF_UP | IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) { // IPv4
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let ip = String(cString: hostname)
                        
                        // Exclude common loopback/internal IPs that might be returned
                        if ip != "127.0.0.1" && ip != "0.0.0.0" {
                            address = ip
                            freeifaddrs(ifaddr) // Free memory
                            return address // Return the first valid non-loopback IPv4
                        }
                    }
                }
            }
        }

        freeifaddrs(ifaddr)
        return address
    }

    func loadManagerAndSendStatus() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard let self = self else { return }

            if let error = error {
                self.logStreamHandler.sendLog("❌ [APP_DELEGATE_MACOS] Error loading manager: \(error.localizedDescription)")
                return
            }

            guard let manager = managers?.first(where: { ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.tunnelBundleId }) else {
                self.logStreamHandler.sendLog("🤷 [APP_DELEGATE_MACOS] Manager not found, sending 'disconnected'.")
                self.vpnStatusStreamHandler.sendStatus("disconnected")
                return
            }
            
            self.logStreamHandler.sendLog("ℹ️ [APP_DELEGATE_MACOS] Initial VPN status: \(self.statusToString(manager.connection.status))")
            self.vpnStatusStreamHandler.sendStatus(self.statusToString(manager.connection.status))
        }
    }

    func isWifiConnected(result: @escaping FlutterResult) {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            let isWifi = path.usesInterfaceType(.wifi)
            monitor.cancel()
            DispatchQueue.main.async {
                result(isWifi)
            }
        }
        monitor.start(queue: DispatchQueue(label: "wifi.monitor"))
    }

    func disconnectVPN(result: @escaping FlutterResult) {
        logStreamHandler.sendLog("🛑 [APP_DELEGATE_MACOS] disconnectVPN called.")
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let error = error {
                self.logStreamHandler.sendLog("❌ [APP_DELEGATE_MACOS] Error loading managers: \(error.localizedDescription)")
                result(FlutterError(code: "LOAD_ERR", message: error.localizedDescription, details: nil))
                return
            }

            guard let manager = managers?.first(where: { ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.tunnelBundleId }) else {
                self.logStreamHandler.sendLog("🤷 [APP_DELEGATE_MACOS] Manager not found.")
                result("VPN not configured.")
                return
            }
            
            manager.connection.stopVPNTunnel()
            self.logStreamHandler.sendLog("🛑 [APP_DELEGATE_MACOS] stopVPNTunnel successfully called!")
            result("Disconnected.")
        }
    }
    
    func setupAndStartVPN(config: String, disableMemoryLimit: Bool, result: @escaping FlutterResult) {
        logStreamHandler.sendLog("🚀 [APP_DELEGATE_MACOS] setupAndStartVPN called.")
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let error = error {
                self.logStreamHandler.sendLog("❌ [APP_DELEGATE_MACOS] Error loading managers: \(error.localizedDescription)")
                result(FlutterError(code: "LOAD_ERR", message: error.localizedDescription, details: nil))
                return
            }
            
            let manager = managers?.first(where: { ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.tunnelBundleId }) ?? NETunnelProviderManager()
            
            let protocolConfiguration = NETunnelProviderProtocol()
            protocolConfiguration.providerBundleIdentifier = self.tunnelBundleId
            protocolConfiguration.serverAddress = "HWL VPN"
            protocolConfiguration.providerConfiguration = ["config": config, "disableMemoryLimit": disableMemoryLimit]
            
            manager.protocolConfiguration = protocolConfiguration
            manager.localizedDescription = "HWL VPN"
            manager.isEnabled = true
            
            manager.saveToPreferences { error in
                if let error = error {
                    self.logStreamHandler.sendLog("❌ [APP_DELEGATE_MACOS] Error saving settings: \(error.localizedDescription)")
                    result(FlutterError(code: "SAVE_ERR", message: error.localizedDescription, details: nil))
                    return
                }
                
                self.logStreamHandler.sendLog("✅ [APP_DELEGATE_MACOS] Settings saved. Reloading and starting...")
                
                manager.loadFromPreferences { error in
                    if let error = error {
                         self.logStreamHandler.sendLog("❌ [APP_DELEGATE_MACOS] Error reloading manager: \(error.localizedDescription)")
                         return
                    }
                    
                    do {
                        try manager.connection.startVPNTunnel(options: [:])
                        self.logStreamHandler.sendLog("🚀 [APP_DELEGATE_MACOS] startVPNTunnel successfully called!")
                        result("Starting! Check VPN status.")
                    } catch {
                        self.logStreamHandler.sendLog("❌ [APP_DELEGATE_MACOS] Error starting VPNTunnel: \(error.localizedDescription)")
                        result(FlutterError(code: "START_ERR", message: error.localizedDescription, details: nil))
                    }
                }
            }
        }
    }
}