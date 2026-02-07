// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'HWL VPN';

  @override
  String get settings => 'Настройки';

  @override
  String get about => 'О приложении';

  @override
  String get language => 'Язык';

  @override
  String get vlessProtocol => 'VLESS';

  @override
  String get hysteria2Protocol => 'Hysteria 2';

  @override
  String get alternativeProtocol => 'Альтернатива';

  @override
  String get selectCountry => 'Выберите страну';

  @override
  String get selectCountryAndServer => 'Выберите страну и сервер';

  @override
  String get servers => 'Серверы';

  @override
  String get noServersForCountry => 'Для этой страны пока нет серверов.';

  @override
  String get statusConnected => 'Подключено';

  @override
  String get statusDisconnected => 'Отключено';

  @override
  String get mixedInbound => 'Mixed Inbound';

  @override
  String get enableMixedInbound => 'Включить Mixed Inbound прокси';

  @override
  String get listenPort => 'Порт';

  @override
  String get dnsProvider => 'DNS провайдер';

  @override
  String get google => 'Google';

  @override
  String get cloudflare => 'Cloudflare';

  @override
  String get adguard => 'AdGuard';

  @override
  String get perAppProxy => 'Прокси для приложений';

  @override
  String get perAppProxyMode => 'Режим';

  @override
  String get allExcept => 'Все кроме';

  @override
  String get onlySelected => 'Только выбранные';

  @override
  String get selectApps => 'Выбрать приложения';

  @override
  String get account => 'Аккаунт';

  @override
  String get linkDevice => 'Привязать устройство';

  @override
  String get unlinkDevice => 'Отвязать устройство';

  @override
  String get selfCheck => 'Самопроверка';

  @override
  String get enterCode => 'Введите ваш код';

  @override
  String get deviceIsLinked => 'Устройство привязано';

  @override
  String get deviceNotLinked => 'Устройство не привязано';

  @override
  String get checking => 'Проверка...';

  @override
  String get unlinking => 'Отвязка...';

  @override
  String get linkSuccess => 'Устройство успешно привязано';

  @override
  String get linkFailed => 'Не удалось привязать устройство';

  @override
  String get unlinkSuccess => 'Устройство успешно отвязано';

  @override
  String get unlinkFailed => 'Не удалось отвязать устройство';

  @override
  String get checkSuccess => 'Устройство привязано корректно';

  @override
  String get checkFailed => 'Устройство не привязано или токен недействителен';

  @override
  String get serverAddress => 'Адрес сервера';

  @override
  String get enterServerAddress => 'Введите адрес сервера (URL или IP:Port)';

  @override
  String get resetValues => 'Сбросить значения';

  @override
  String get resetWarningTitle => 'Сбросить значения?';

  @override
  String get resetWarningContent => 'Это отвяжет ваше устройство и создаст новый идентификатор. Это действие необратимо.';

  @override
  String get cancel => 'Отмена';

  @override
  String get reset => 'Сбросить';

  @override
  String get resetSuccess => 'Значения были сброшены.';

  @override
  String get deviceNameOptional => 'Название устройства (необязательно)';

  @override
  String get selectServerFirst => 'Пожалуйста, сначала выберите сервер.';

  @override
  String get connectingStatus => 'Подключение...';

  @override
  String get vpnKeyReceivedTitle => 'VPN ключ получен';

  @override
  String get failedToGetKey => 'Не удалось получить ключ VPN.';

  @override
  String get servicesOnline => 'Все сервисы онлайн';

  @override
  String get servicesOffline => 'Сервисы временно недоступны';

  @override
  String get welcomeMessage => 'Добро пожаловать в HWL VPN';

  @override
  String get onboardingDescription => 'Авторизуйтесь, чтобы получить доступ ко всем функциям, или продолжите как гость.';

  @override
  String get authorize => 'Войти';

  @override
  String get continueAsGuest => 'Продолжить как гость';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get unlinkDeviceWarningTitle => 'Отвязать устройство?';

  @override
  String get unlinkDeviceWarningContent => 'Это действие отвяжет ваше устройство. Вы уверены?';

  @override
  String get changeDeviceName => 'Изменить имя устройства';

  @override
  String get save => 'Сохранить';

  @override
  String get resetSettings => 'Сбросить настройки';

  @override
  String get resetSettingsWarningTitle => 'Сбросить настройки?';

  @override
  String get resetSettingsWarningContent => 'Это сбросит все настройки приложения к значениям по умолчанию. Это действие необратимо.';

  @override
  String get guestModeActive => 'Сейчас вы в режиме гостя';

  @override
  String get updateFailed => 'Ошибка при обновлении';

  @override
  String get persistentNotification => 'Постоянное уведомление';

  @override
  String get enableMemoryLimit => 'Включить лимит памяти';

  @override
  String get notRecommended => 'Не рекомендуется';

  @override
  String get enableMemoryLimitWarningTitle => 'Включить лимит памяти?';

  @override
  String get enableMemoryLimitWarningContent => 'Включение лимита памяти может вызвать нестабильность VPN и в целом не рекомендуется. Продолжить?';

  @override
  String get enable => 'Включить';

  @override
  String get ok => 'OK';

  @override
  String get showSystemApps => 'Показывать системные приложения';

  @override
  String get couldNotVerifyStatus => 'Не удалось проверить статус, проверьте подключение к сети.';

  @override
  String get checkFailedCouldNotConnect => 'Ошибка проверки: не удалось подключиться к серверу.';

  @override
  String get pingNA => 'Н/Д';

  @override
  String get freeTag => 'Бесплатно';

  @override
  String get premiumTag => 'Premium';

  @override
  String get mixedInboundDescription => 'Включает локальный прокси-сервер, который может принимать соединения HTTP и SOCKS5 на одном порту. Это позволяет другим устройствам в вашей локальной сети использовать VPN-соединение через это устройство (например, в режиме модема), при условии, что вы настроите их на использование этого устройства в качестве прокси.';

  @override
  String get perAppProxyDescription => 'Позволяет выбрать, какие приложения должны использовать VPN-соединение. Вы можете либо включить только выбранные приложения, либо исключить выбранные приложения.';

  @override
  String get hideConsoleWindow => 'Скрыть окно консоли';

  @override
  String get hideConsoleWindowDescription => 'Для процесса sing-box в Windows';

  @override
  String get excludedDomains => 'Исключенные домены';

  @override
  String get excludedDomainsDescription => 'Список доменов через запятую для исключения из VPN.';

  @override
  String get excludedDomainSuffixes => 'Исключенные суффиксы доменов';

  @override
  String get excludedDomainSuffixesDescription => 'Суффиксы доменов для исключения из VPN, например: .local, .lan';

  @override
  String get closeBehavior => 'Поведение кнопки закрытия';

  @override
  String get minimizeToTray => 'Сворачивать в трей';

  @override
  String get exitOnClose => 'Закрывать приложение';

  @override
  String get show => 'Показать';

  @override
  String get exit => 'Выход';

  @override
  String get enableLogging => 'Вести логи';

  @override
  String get enableLoggingWarningTitle => 'Включить логирование?';

  @override
  String get enableLoggingWarningContent => 'Включение логирования может занимать место на диске и незначительно снижать производительность. Эта функция предназначена в основном для разработчиков или для устранения проблем со службой технической поддержки. Вы уверены, что хотите включить его?';

  @override
  String get showLogs => 'Показать логи';

  @override
  String get logsTitle => 'Логи';

  @override
  String get clearLogsTooltip => 'Очистить логи';

  @override
  String get noLogsToShow => 'Нет логов для отображения.';

  @override
  String get launchOnStartup => 'Запускать при входе в систему';

  @override
  String get faqTelegramChannel => 'Telegram канал';

  @override
  String get faqTelegramChannelLink => 'https://t.me/hwlab_official';

  @override
  String get faqWebsite => 'Наш сайт';

  @override
  String get faqWebsiteLink => 'https://hinaworklab.tech/#/vpn';

  @override
  String get faqSupportEmail => 'Почта поддержки';

  @override
  String get faqSupportEmailAddress => 'hinaworklab@yandex.com';

  @override
  String get faqQ6 => 'Что делать, если возникают ошибки при работе приложения?';

  @override
  String get faqA6 => 'Если вы сталкиваетесь с постоянными проблемами, попробуйте сбросить значения приложения. Это отвяжет ваше устройство и создаст новый идентификатор, по сути, сбросив приложение к исходному состоянию. Это действие необратимо и находится на экране \'Настройки\' под кнопкой \'Сбросить значения\'.';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get termsOfUse => 'Пользовательское соглашение';

  @override
  String get iAccept => 'Я принимаю';

  @override
  String get and => 'и';

  @override
  String get youMustAccept => 'Вы должны принять условия, чтобы продолжить';

  @override
  String get privacyPolicyLink => 'https://hinaworklab.tech/#/privacy-hwl-vpn';

  @override
  String get termsOfUseLink => 'https://hinaworklab.tech/#/terms-hwl-vpn';

  @override
  String get personalKeysExplanationHysteria2 => '• Hysteria 2 (hysteria2://пароль@хост:порт?параметры...)';

  @override
  String get legal => 'Правовая информация';

  @override
  String get updateTermsMessage => 'Пожалуйста, ознакомьтесь и примите наши обновленные условия, чтобы продолжить.';

  @override
  String get subscriptionExpired => 'Подписка истекла. Доступны только бесплатные серверы.';

  @override
  String get renewSubscription => 'Продлить';

  @override
  String get personalKeys => 'Персональные ключи';

  @override
  String get personalKeysEnterLink => 'Введите ссылку для подключения - vless://4721231d-aae1-...';

  @override
  String get personalKeysClear => 'Очистить';

  @override
  String get personalKeysWarningTitle => 'Внимание:';

  @override
  String get personalKeysWarningBody => ' Этот раздел предназначен только для опытных пользователей.';

  @override
  String get personalKeysExplanation1 => 'Сюда вы можете вставить и использовать собственный ключ.';

  @override
  String get personalKeysExplanation2 => 'Поддерживаемые конфигурации:';

  @override
  String get personalKeysExplanationVless => '• vless (TCP) + reality (vless без reality не работает)';

  @override
  String get personalKeysExplanationSsh => '• ssh формат user:private_key@ip:port (Приватный ключ дожен быть закодирован в Base64)';

  @override
  String get personalKeysExplanation3 => 'После вставки ключа вернитесь на главный экран и нажмите кнопку подключения. Если поле с ключом заполнено, приложение будет использовать его, игнорируя сервер, выбранный из списка. Важно: используйте свой ключ только если вы разбираетесь в VPN-конфигурациях и он у вас есть.';

  @override
  String get faqAndContacts => 'FAQ и Техподдержка';

  @override
  String get faqSupport => 'Техподдержка';

  @override
  String get faqBot => 'Наш бот';

  @override
  String get faqTitle => 'Часто задаваемые вопросы';

  @override
  String get faqQ1 => 'Что такое \'Персональный ключ\'?';

  @override
  String get faqA1 => 'Это функция, позволяющая использовать для подключения собственный ключ конфигурации (ссылку), вместо выбора сервера из общего списка. Это дает больше гибкости и контроля над вашим VPN-соединением.';

  @override
  String get faqQ2 => 'Какой протокол выбрать?';

  @override
  String get faqA2 => 'VLESS — предпочтительный вариант для большинства. Hysteria 2 обеспечивает лучшую скорость в плохих сетях, но может быть менее стабильным. Используйте \'Альтернативу\' (SSH), если остальные не работают.';

  @override
  String get faqQ3 => 'Почему у меня низкая скорость?';

  @override
  String get faqA3 => 'Скорость зависит от многих факторов: загруженность сервера, расстояние до него, качество вашего интернет-соединения и ограничения вашего провайдера. Попробуйте выбрать другой сервер или подключиться в другое время.';

  @override
  String get faqQ4 => 'Приложение не подключается, что делать?';

  @override
  String get faqA4 => '1. Проверьте интернет-соединение.\n2. Убедитесь, что вы выбрали сервер.\n3. Попробуйте другой сервер или протокол.\n4. Если вы используете персональный ключ, убедитесь, что он корректен и активен.\n5. Свяжитесь с нашей техподдержкой.';

  @override
  String get faqQ5 => 'Как проверить соединение с серверами?';

  @override
  String get faqA5 => 'На главном экране потяните экран вниз, чтобы обновить список доступных серверов.';

  @override
  String get mixedInboundIpWarning => 'IP-адрес вашего устройства в настоящее время недоступен. Используется 0.0.0.0. Некоторые функции могут работать некорректно.';

  @override
  String get mixedInboundIpUnavailable => 'IP-адрес устройства недоступен';

  @override
  String get mixedInboundIosMacWarning => 'На iOS и macOS это может не работать в режиме точки доступа.';

  @override
  String get offlineMode => 'Автономный режим';

  @override
  String get offlineModeDescription => 'Отключает соединение с сервером и требования API. Использовать только с Персональными ключами.';

  @override
  String get offlineModeWarningTitle => 'Включить автономный режим?';

  @override
  String get offlineModeWarningContent => 'Это отключит доступ к публичным серверам и функциям аккаунта. Для подключения вам понадобится Персональный ключ. Продолжить?';
}
