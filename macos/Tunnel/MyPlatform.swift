import Foundation
import Libbox
import NetworkExtension
import Network

// Вспомогательная функция для записи логов в общий файл
func logToConsole(_ message: String) {
    // ВАЖНО: Вставьте ваш App Group ID
    let appGroupId = "group.com.hwl.hwlVpn"
    
    guard let fileURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
        .appendingPathComponent("tunnel_debug.log") else { return }
    
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let timestamp = formatter.string(from: Date())
    
    // Используем [PLATFORM] для логов из этого файла
    let logMessage = "\(timestamp) [PLATFORM]: \(message)\n"
    
    if let data = logMessage.data(using: .utf8) {
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            try? fileHandle.close()
        } else {
            try? data.write(to: fileURL)
        }
    }
}


class MyPlatform: NSObject, LibboxPlatformInterfaceProtocol, LibboxCommandServerHandlerProtocol {
    
    private weak var tunnelProvider: PacketTunnelProvider?
    private var nwMonitor: NWPathMonitor?

    init(tunnelProvider: PacketTunnelProvider) {
        self.tunnelProvider = tunnelProvider
    }

    // MARK: - LibboxCommandServerHandlerProtocol Stubs
    
    func getSystemProxyStatus() -> LibboxSystemProxyStatus? {
        logToConsole("[CommandServer] getSystemProxyStatus called")
        // Возвращаем пустой статус, так как мы не управляем системным прокси
        return LibboxSystemProxyStatus()
    }
    
    func postServiceClose() {
        logToConsole("[CommandServer] postServiceClose called")
        // Сюда можно добавить логику, если нужно что-то сделать после закрытия сервиса
    }
    
    func serviceReload() throws {
        logToConsole("[CommandServer] serviceReload called. Full restart not implemented yet.")
        // In a real app, you might need to coordinate a full service restart here.
        // For now, we just log the event.
    }
    
    func setSystemProxyEnabled(_ isEnabled: Bool) throws {
        logToConsole("[CommandServer] setSystemProxyEnabled called with: \(isEnabled)")
        // Мы не управляем системным прокси из расширения, поэтому оставляем пустым
    }

    // MARK: - LibboxPlatformInterfaceProtocol Implementation

    // Логи от самого sing-box
    func writeLog(_ message: String?) {
        guard let message = message else { return }
        logToConsole("[sing-box] \(message)")
    }
    
    // Настройка и создание TUN интерфейса
    func openTun(_ options: LibboxTunOptionsProtocol?, ret0_ tunFd: UnsafeMutablePointer<Int32>?) throws {
        guard let tunnelProvider = self.tunnelProvider else {
            throw NSError(domain: "MyPlatform", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tunnel provider is not available"])
        }
        guard let options = options else {
            throw NSError(domain: "MyPlatform", code: -1, userInfo: [NSLocalizedDescriptionKey: "TUN options are nil"])
        }
        guard let tunFd = tunFd else {
            throw NSError(domain: "MyPlatform", code: -1, userInfo: [NSLocalizedDescriptionKey: "TUN file descriptor pointer is nil"])
        }

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = NSNumber(value: options.getMTU())

        // --- Настройка DNS ---
        do {
            let dnsServer = try options.getDNSServerAddress()
            let dnsSettings = NEDNSSettings(servers: [dnsServer.value])
            dnsSettings.matchDomains = [""] // Для всего трафика
            settings.dnsSettings = dnsSettings
            logToConsole("DNS настроен на: \(dnsServer.value)")
        } catch {
            logToConsole("⚠️ Не удалось получить DNS сервер от sing-box: \(error.localizedDescription)")
        }

        // --- Настройка маршрутов IPv4 ---
        let ipv4Settings = NEIPv4Settings(addresses: ["192.0.2.1"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        logToConsole("Настроен маршрут по умолчанию для IPv4.")

        // --- Настройка маршрутов IPv6 ---
        let ipv6Settings = NEIPv6Settings(addresses: ["::1"], networkPrefixLengths: [128])
        ipv6Settings.includedRoutes = [NEIPv6Route.default()]
        settings.ipv6Settings = ipv6Settings
        logToConsole("Настроен маршрут по умолчанию для IPv6.")

        // --- Применение настроек ---
        tunnelProvider.setTunnelNetworkSettings(settings) { error in
            if let error = error {
                logToConsole("❌ Ошибка применения настроек сети: \(error.localizedDescription)")
                // Ошибка здесь асинхронна, мы не можем ее просто бросить.
                // sing-box уже будет заблокирован в ожидании FD, лучший вариант - остановить туннель.
                self.tunnelProvider?.cancelTunnelWithError(error)
            } else {
                logToConsole("✅ Настройки сети успешно применены.")
            }
        }
        
        // --- Получение файлового дескриптора ---
        // Эта функция будет ждать, пока дескриптор не станет доступен, без таймаута в 5 секунд.
        let fd = LibboxGetTunnelFileDescriptor()
        
        if fd != -1 {
            tunFd.pointee = fd
            logToConsole("✅ TUN-FD получен через LibboxGetTunnelFileDescriptor: \(fd)")
        } else {
            throw NSError(domain: "MyPlatform", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить файловый дескриптор туннеля."])
        }
    }
    
    // sing-box сам будет разбираться с сокетами
    func usePlatformAutoDetectControl() -> Bool {
        return false
    }
    
    func autoDetectControl(_ fd: Int32) throws {
        // не реализуем, так как usePlatformAutoDetectControl = false
    }
    
    // --- Мониторинг сети ---
    
    func startDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
        guard let listener = listener else { return }
        
        nwMonitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var firstUpdate = true
        
        nwMonitor?.pathUpdateHandler = { path in
            self.updateInterface(listener: listener, path: path)
            if firstUpdate {
                firstUpdate = false
                semaphore.signal()
            }
        }
        nwMonitor?.start(queue: DispatchQueue(label: "NetworkMonitor"))
        _ = semaphore.wait(timeout: .now() + 2) // Ждем первого обновления
        logToConsole("Мониторинг сети запущен.")
    }

    private func updateInterface(listener: LibboxInterfaceUpdateListenerProtocol, path: Network.NWPath) {
        if path.status == .satisfied, let interface = path.availableInterfaces.first {
            listener.updateDefaultInterface(interface.name, interfaceIndex: Int32(interface.index), isExpensive: path.isExpensive, isConstrained: path.isConstrained)
            //logToConsole("Сетевой интерфейс обновлен: \(interface.name)")
        } else {
            listener.updateDefaultInterface("", interfaceIndex: -1, isExpensive: false, isConstrained: false)
            logToConsole("Сетевой интерфейс потерян.")
        }
    }
    
    func closeDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
        nwMonitor?.cancel()
        nwMonitor = nil
        logToConsole("Мониторинг сети остановлен.")
    }
    
    func getInterfaces() throws -> LibboxNetworkInterfaceIteratorProtocol {
        guard let monitor = nwMonitor else {
            throw NSError(domain: "MyPlatform", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network monitor not started"])
        }
        let interfaces = monitor.currentPath.availableInterfaces.map { nwInterface -> LibboxNetworkInterface in
            let interface = LibboxNetworkInterface()
            interface.name = nwInterface.name
            interface.index = Int32(nwInterface.index)
            return interface
        }
        return MyNetworkInterfaceIterator(interfaces)
    }
    
    // --- Остальные методы (заглушки) ---
    
    func findConnectionOwner(_ ipProtocol: Int32, sourceAddress: String?, sourcePort: Int32, destinationAddress: String?, destinationPort: Int32, ret0_: UnsafeMutablePointer<Int32>?) throws {
        ret0_?.pointee = -1
    }
    
    func packageName(byUid uid: Int32, error: NSErrorPointer) -> String {
        return ""
    }
    
    func uid(byPackageName packageName: String?, ret0_: UnsafeMutablePointer<Int32>?) throws {
        ret0_?.pointee = -1
    }
    
    func useProcFS() -> Bool {
        return false
    }
    
    func underNetworkExtension() -> Bool {
        return true
    }
    
    func includeAllNetworks() -> Bool {
        return true // Включаем все сети для простоты
    }
    
    func clearDNSCache() {
        // Можно реализовать при необходимости
    }
    
    func readWIFIState() -> LibboxWIFIState? {
        return nil
    }
    
    func localDNSTransport() -> LibboxLocalDNSTransportProtocol? {
        return nil
    }
    
    func systemCertificates() -> LibboxStringIteratorProtocol? {
        return nil
    }
    
    func send(_ notification: LibboxNotification?) throws {
        // Можно реализовать при необходимости
    }
}

// Вспомогательный класс-итератор для getInterfaces
private class MyNetworkInterfaceIterator: NSObject, LibboxNetworkInterfaceIteratorProtocol {
    private var iterator: IndexingIterator<[LibboxNetworkInterface]>
    private var nextValue: LibboxNetworkInterface?

    init(_ interfaces: [LibboxNetworkInterface]) {
        self.iterator = interfaces.makeIterator()
    }

    func hasNext() -> Bool {
        if nextValue == nil {
            nextValue = iterator.next()
        }
        return nextValue != nil
    }

    func next() -> LibboxNetworkInterface? {
        if nextValue != nil {
            let result = nextValue
            nextValue = nil
            return result
        }
        return iterator.next()
    }
}
