import NetworkExtension
import Foundation
import Libbox

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var boxService: LibboxBoxService?
    private let appGroupId = "group.com.hwl.hwlVpn" // Declared once at class level

    private func clearLogFile() {
        guard let fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("tunnel_debug.log") else {
            return
        }
        // Overwrite with empty data to clear the log.
        try? Data().write(to: fileURL)
    }

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        clearLogFile()
        logToConsole("🚀 [TUNNEL_PROVIDER] startTunnel called.")

        // --- Cache Validity Check ---
        let userDefaults = UserDefaults(suiteName: appGroupId)
        let savedTimestamp = userDefaults?.integer(forKey: "cacheTimestamp") ?? 0

        // If timestamp was never saved, deny connection. User must open app first.
        if savedTimestamp == 0 {
            let errorMessage = "No cache timestamp found. Please open the app to connect at least once."
            logToConsole("❌ [TUNNEL_PROVIDER] \(errorMessage)")
            let error = NSError(domain: "PacketTunnelError", code: -3, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            completionHandler(error)
            return
        }

        // 7 days in milliseconds (7 * 24 * 60 * 60 * 1000)
        let sevenDaysInMillis = 604800000
        let currentTimestamp = Int(Date().timeIntervalSince1970 * 1000)

        if (currentTimestamp - savedTimestamp > sevenDaysInMillis) {
            let errorMessage = "VPN configuration expired. Please open the app to refresh."
            logToConsole("❌ [TUNNEL_PROVIDER] Cache is stale, connection denied. Saved: \(savedTimestamp), Current: \(currentTimestamp)")
            let error = NSError(domain: "PacketTunnelError", code: -2, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            completionHandler(error)
            return
        }
        logToConsole("✅ [TUNNEL_PROVIDER] Cache timestamp is valid (Saved: \(savedTimestamp), Current: \(currentTimestamp)).")
        // --- End of Cache Validity Check ---

        
        // Получаем конфигурацию из `providerConfiguration`, переданную из AppDelegate
        guard let config = (self.protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration,
              let jsonConfig = config["config"] as? String else {
            let error = NSError(domain: "PacketTunnelError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Конфигурация не найдена."])
            logToConsole("❌ [TUNNEL_PROVIDER] \(error.localizedDescription)")
            completionHandler(error)
            return
        }
        logToConsole("✅ [TUNNEL_PROVIDER] Получена конфигурация из AppDelegate.")
        
        // --- Настройка путей для sing-box ---
        guard let groupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            let error = NSError(domain: "PacketTunnelError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить доступ к App Group контейнеру."])
            logToConsole("❌ [TUNNEL_PROVIDER] \(error.localizedDescription)") // Corrected error message
            completionHandler(error)
            return
        }
        let groupContainerPath = groupContainerURL.path
        
        let setupOptions = LibboxSetupOptions()
        setupOptions.basePath = groupContainerPath
        setupOptions.workingPath = groupContainerPath
        setupOptions.tempPath = groupContainerPath
        
        // Get the memory limit setting, default to false (limit enabled) to match old behavior
        let disableMemoryLimit = config["disableMemoryLimit"] as? Bool ?? false

        // The Go function expects `true` to enable the limit.
        // Our setting is `disable_memory_limit`, so we need to invert it.
        logToConsole("Setting memory limit disabled: \(disableMemoryLimit)")
        LibboxSetMemoryLimit(!disableMemoryLimit)

        var nsError: NSError?
        let setupSuccess = LibboxSetup(setupOptions, &nsError)
        if !setupSuccess {
            logToConsole("❌ [TUNNEL_PROVIDER] Failed to setup sing-box: \(nsError?.localizedDescription ?? "unknown error")")
            completionHandler(nsError)
            return
        }
        logToConsole("✅ [TUNNEL_PROVIDER] LibboxSetup completed successfully at path: \(groupContainerPath)")


        // --- Запуск сервиса sing-box ---
        let platform = MyPlatform(tunnelProvider: self)
        
        var serviceError: NSError?
        self.boxService = LibboxNewService(jsonConfig, platform, &serviceError)
        if let error = serviceError {
            logToConsole("❌ [TUNNEL_PROVIDER] Failed to create sing-box service: \(error.localizedDescription)")
            completionHandler(error)
            return
        }
        
        do {
            try self.boxService?.start()
            logToConsole("✅ [TUNNEL_PROVIDER] sing-box service started successfully.")
            completionHandler(nil)
        } catch {
            logToConsole("❌ [TUNNEL_PROVIDER] Failed to start sing-box service: \(error.localizedDescription)")
            completionHandler(error)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logToConsole("🛑 [TUNNEL_PROVIDER] stopTunnel called with reason: \(reason.rawValue)")
        
        do {
            try self.boxService?.close()
            self.boxService = nil
            logToConsole("✅ [TUNNEL_PROVIDER] sing-box service stopped.")
        } catch {
            logToConsole("❌ [TUNNEL_PROVIDER] Failed to stop sing-box service: \(error.localizedDescription)")
        }
        
        completionHandler()
    }
    
    // Остальные методы можно пока не трогать
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        logToConsole("ℹ️ [TUNNEL_PROVIDER] handleAppMessage called.")
        completionHandler?(nil)
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        //logToConsole("😴 [TUNNEL_PROVIDER] sleep called.")
        boxService?.pause()
        completionHandler()
    }
    
    override func wake() {
        //logToConsole("☀️ [TUNNEL_PROVIDER] wake called.")
        boxService?.wake()
    }
}
