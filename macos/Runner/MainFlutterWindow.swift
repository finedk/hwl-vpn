import Cocoa
import FlutterMacOS
import NetworkExtension

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // 1. Стандартная регистрация плагинов
    RegisterGeneratedPlugins(registry: flutterViewController)

    // 2. Наша кастомная настройка
    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
        // Очищаем лог-файл при старте
        appDelegate.clearLogFile()
        // Запускаем чтение логов
        appDelegate.startLogWatcher()
        
        appDelegate.logStreamHandler.sendLog("🚀 [MainFlutterWindow] awakeFromNib called.")
        
        // Настраиваем все наши каналы
        appDelegate.setupFlutterChannels(controller: flutterViewController)
        
        // Добавляем наблюдателя за статусом VPN
        NotificationCenter.default.addObserver(
            appDelegate,
            selector: #selector(AppDelegate.vpnStatusDidChange(_:)),
            name: .NEVPNStatusDidChange,
            object: nil
        )
        
        // Загружаем начальный статус VPN
        appDelegate.loadManagerAndSendStatus()
    } else {
        print("Error: Could not get AppDelegate instance.")
    }

    // --- Установка размера и положения окна и его отображение ---
    let newSize = NSSize(width: 450, height: 800)
    self.setContentSize(newSize)
    self.center()
    self.makeKeyAndOrderFront(nil)

    super.awakeFromNib()

    
  }
}
