import UIKit
import Flutter
import NetworkExtension

// Стример для отправки логов в Flutter
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

// Стример для отправки статуса VPN в Flutter
class VpnStatusStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
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
@objc class AppDelegate: FlutterAppDelegate {
    
    // ВАЖНО: Вставьте сюда свой Bundle ID точь-в-точь как в Xcode
    let tunnelBundleId = "com.hwl.hwl-vpn.Tunnel"
    let appGroupId = "group.com.hwl.hwlVpn" // Ваш App Group
    var logTimer: Timer?
    var lastFileOffset: UInt64 = 0
    private let logStreamHandler = LogStreamHandler()
    private let vpnStatusStreamHandler = VpnStatusStreamHandler()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        GeneratedPluginRegistrant.register(with: self)
        
        // 1. Очищаем старый лог при запуске приложения
        clearLogFile()
        
        // 2. Запускаем "слежку" за файлом логов
        startLogWatcher()
        
        logStreamHandler.sendLog("🚀 [APP_DELEGATE] application didFinishLaunchingWithOptions called.")
        
        let registrar = self.registrar(forPlugin: "com.hwl.hwl-vpn")!
        let messenger = registrar.messenger()
        
        // Канал для управления VPN
        let vpnChannel = FlutterMethodChannel(name: "com.hwl.hwl-vpn/control",
                                              binaryMessenger: messenger)
        
        // Канал для стриминга логов
        let logChannel = FlutterEventChannel(name: "com.hwl.hwl-vpn/logs",
                                             binaryMessenger: messenger)
        logChannel.setStreamHandler(logStreamHandler)

        // Канал для статуса VPN
        let vpnStatusChannel = FlutterEventChannel(name: "com.hwl.hwl-vpn/status",
                                             binaryMessenger: messenger)
        vpnStatusChannel.setStreamHandler(vpnStatusStreamHandler)

        // Добавляем наблюдателя за статусом VPN
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange(_:)),
            name: .NEVPNStatusDidChange,
            object: nil
        )
        
        vpnChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            if call.method == "connect" {
                self.logStreamHandler.sendLog("🚀 [APP_DELEGATE] Received 'connect' call from Flutter.")
                guard let args = call.arguments as? [String: Any],
                      let config = args["config"] as? String else {
                    let errorMessage = "Missing 'config' argument in 'connect' call"
                    self.logStreamHandler.sendLog("❌ [APP_DELEGATE] \(errorMessage)")
                    result(FlutterError(code: "INVALID_ARG", message: errorMessage, details: nil))
                    return
                }
                // Extract the new value, default to false (limit enabled)
                let disableMemoryLimit = args["disableMemoryLimit"] as? Bool ?? false
                self.setupAndStartVPN(config: config, disableMemoryLimit: disableMemoryLimit, result: result)
            } else if call.method == "disconnect" {
                self.logStreamHandler.sendLog("🛑 [APP_DELEGATE] Received 'disconnect' call from Flutter.")
                self.disconnectVPN(result: result)
            } else if call.method == "getIpAddress" {
                result(self.getIPAddress())
            } else if call.method == "isWifiConnected" {
                self.isWifiConnected(result: result)
            } else if call.method == "saveCacheTimestamp" {
                self.logStreamHandler.sendLog("💾 [APP_DELEGATE_IOS] Received 'saveCacheTimestamp' call.")
                guard let args = call.arguments as? [String: Any],
                      let timestamp = args["timestamp"] as? Int else {
                    let errorMessage = "Missing 'timestamp' argument in 'saveCacheTimestamp' call"
                    self.logStreamHandler.sendLog("❌ [APP_DELEGATE_IOS] \(errorMessage)")
                    result(FlutterError(code: "INVALID_ARG", message: errorMessage, details: nil))
                    return
                }
                let userDefaults = UserDefaults(suiteName: self.appGroupId)
                userDefaults?.set(timestamp, forKey: "cacheTimestamp")
                result(nil)
            } else {
                self.logStreamHandler.sendLog("⚠️ [APP_DELEGATE] Unimplemented method: \(call.method)")
                result(FlutterMethodNotImplemented)
            }
        })
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        // When the app returns to the foreground, re-check the VPN status
        // to ensure the UI is in sync.
        loadManagerAndSendStatus()
    }

    // --- Логика чтения логов ---
    
    func clearLogFile() {
        guard let fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("tunnel_debug.log") else { return }
        
        // Удаляем файл или создаем пустой
        try? FileManager.default.removeItem(at: fileURL)
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        lastFileOffset = 0
        logStreamHandler.sendLog("🌀 [APP_DELEGATE] Log file cleared.")
    }
    
    func startLogWatcher() {
        // Таймер срабатывает каждые 0.5 секунды
        logTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.readNewLogs()
        }
        logStreamHandler.sendLog("👀 [APP_DELEGATE] Log watcher started.")
    }
    
    func readNewLogs() {
        guard let fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("tunnel_debug.log") else { return }
        
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return }
        
        defer {
            try? fileHandle.close()
        }

        // --- Log Truncation Detection ---
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        let currentSize = attributes?[.size] as? UInt64 ?? 0

        if currentSize < lastFileOffset {
            lastFileOffset = 0
            // Send a special message to tell Flutter to clear its log buffer
            self.logStreamHandler.sendLog("__CLEAR_LOGS__\n")
        }
        // ---------------------------------
        
        // Переходим к последней прочитанной позиции
        fileHandle.seek(toFileOffset: lastFileOffset)
        
        let data = fileHandle.readDataToEndOfFile()
        if !data.isEmpty {
            // Обновляем курсор
            lastFileOffset = fileHandle.offsetInFile
            
            if let string = String(data: data, encoding: .utf8) {
                // ОТПРАВЛЯЕМ В FLUTTER ЧЕРЕЗ КАНАЛ
                self.logStreamHandler.sendLog(string)
            }
        }
    }
    
    // --- Логика статуса VPN ---

    @objc func vpnStatusDidChange(_ notification: Notification) {
        guard let connection = notification.object as? NEVPNConnection else {
            return
        }
        let status = connection.status
        logStreamHandler.sendLog("ℹ️ [APP_DELEGATE] VPN status changed: \(statusToString(status))")
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
        var address: String = "?.?.?.?"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return address }
        guard let firstAddr = ifaddr else { return address }

        var wifiIP: String?
        var hotspotIP: String?

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            if (flags & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK)) == (IFF_UP | IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let ip = String(cString: hostname)
                        let name = String(cString: ptr.pointee.ifa_name)

                        if name == "en0" { // Wi-Fi
                            wifiIP = ip
                        } else if name.starts(with: "bridge") { // Hotspot
                            hotspotIP = ip
                        }
                    }
                }
            }
        }

        freeifaddrs(ifaddr)

        if let ip = hotspotIP {
            address = ip
        } else if let ip = wifiIP {
            address = ip
        }
        
        return address
    }

    func loadManagerAndSendStatus() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard let self = self else { return }

            if let error = error {
                self.logStreamHandler.sendLog("❌ [APP_DELEGATE] Error loading manager for status: \(error.localizedDescription)")
                return
            }

            guard let manager = managers?.first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.tunnelBundleId
            }) else {
                self.logStreamHandler.sendLog("🤷 [APP_DELEGATE] Manager not found for status, sending 'disconnected'.")
                self.vpnStatusStreamHandler.sendStatus("disconnected")
                return
            }
            
            self.logStreamHandler.sendLog("ℹ️ [APP_DELEGATE] Initial VPN status: \(self.statusToString(manager.connection.status))")
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

    // --- Логика управления VPN ---

    func disconnectVPN(result: @escaping FlutterResult) {
        logStreamHandler.sendLog("🛑 [APP_DELEGATE] disconnectVPN called.")
        // Загружаем конфигурации
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let error = error {
                self.logStreamHandler.sendLog("❌ [APP_DELEGATE] Ошибка загрузки менеджеров для отключения: \(error.localizedDescription)")
                result(FlutterError(code: "LOAD_ERR", message: error.localizedDescription, details: nil))
                return
            }

            // Ищем наш менеджер
            guard let manager = managers?.first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.tunnelBundleId
            }) else {
                self.logStreamHandler.sendLog("🤷 [APP_DELEGATE] Менеджер не найден, возможно VPN и не был запущен.")
                result("VPN не был настроен ранее.")
                return
            }
            
            // Останавливаем туннель
            manager.connection.stopVPNTunnel()
            self.logStreamHandler.sendLog("🛑 [APP_DELEGATE] stopVPNTunnel успешно вызван!")
            result("Отключено.")
        }
    }
    
    func setupAndStartVPN(config: String, disableMemoryLimit: Bool, result: @escaping FlutterResult) {
        logStreamHandler.sendLog("🚀 [APP_DELEGATE] setupAndStartVPN called.")
        // ИСПОЛЬЗУЕМ ИМЕННО NETunnelProviderManager, а не NEVPNManager
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let error = error {
                self.logStreamHandler.sendLog("❌ [APP_DELEGATE] Ошибка загрузки менеджеров: \(error.localizedDescription)")
                result(FlutterError(code: "LOAD_ERR", message: error.localizedDescription, details: nil))
                return
            }
            
            // Ищем, есть ли уже созданный профиль для нашего туннеля
            let manager: NETunnelProviderManager
            if let existingManager = managers?.first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.tunnelBundleId
            }) {
                manager = existingManager
                self.logStreamHandler.sendLog("♻️ [APP_DELEGATE] Найден существующий менеджер.")
            } else {
                manager = NETunnelProviderManager()
                self.logStreamHandler.sendLog("🆕 [APP_DELEGATE] Создаем новый менеджер.")
            }
            
            // Настройка конфигурации
            let protocolConfiguration = NETunnelProviderProtocol()
            protocolConfiguration.providerBundleIdentifier = self.tunnelBundleId
            protocolConfiguration.serverAddress = "HWL VPN" // Формальность для iOS
            
            // ВАЖНО: Передаем конфиг в расширение через providerConfiguration,
            // это более надежный способ, чем options в startVPNTunnel
            protocolConfiguration.providerConfiguration = [
                "config": config,
                "disableMemoryLimit": disableMemoryLimit
            ]
            
            manager.protocolConfiguration = protocolConfiguration
            manager.localizedDescription = "HWL VPN" // Название в настройках iOS
            manager.isEnabled = true
            
            // Сохранение
            manager.saveToPreferences { error in
                if let error = error {
                    self.logStreamHandler.sendLog("❌ [APP_DELEGATE] Ошибка сохранения настроек: \(error.localizedDescription)")
                    result(FlutterError(code: "SAVE_ERR", message: error.localizedDescription, details: nil))
                    return
                }
                
                self.logStreamHandler.sendLog("✅ [APP_DELEGATE] Настройки сохранены. Обновляем и запускаем...")
                
                // Важный шаг: перезагрузка менеджера перед стартом
                manager.loadFromPreferences { error in
                    if let error = error {
                         self.logStreamHandler.sendLog("❌ [APP_DELEGATE] Ошибка повторной загрузки менеджера: \(error.localizedDescription)")
                         return
                    }
                    
                    do {
                        // options в startVPNTunnel могут быть ненадежны, основная передача - через providerConfiguration
                        try manager.connection.startVPNTunnel(options: [:])
                        self.logStreamHandler.sendLog("🚀 [APP_DELEGATE] startVPNTunnel успешно вызван!")
                        result("Запущено! Проверьте VPN в шторке.")
                    } catch {
                        self.logStreamHandler.sendLog("❌ [APP_DELEGATE] Ошибка старта VPNTunnel: \(error.localizedDescription)")
                        result(FlutterError(code: "START_ERR", message: error.localizedDescription, details: nil))
                    }
                }
            }
        }
    }
}

