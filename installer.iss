; Inno Setup Script for HWL VPN
; --

[Setup]
AppName=HWL VPN
AppVersion=1.0.4
AppPublisher=HW Lab
DefaultDirName={autopf64}\HWL VPN
DefaultGroupName=HWL VPN
OutputBaseFilename=hwl_vpn_setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; Запрашиваем права администратора (нужны для VPN и firewall)
PrivilegesRequired=admin
; Иконка установщика
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\hwl_vpn.exe
; Попытка закрыть приложения (используется вместе с кодом ниже)
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Icons]
Name: "{group}\HWL VPN"; Filename: "{app}\hwl_vpn.exe"
Name: "{group}\{cm:UninstallProgram,HWL VPN}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\HWL VPN"; Filename: "{app}\hwl_vpn.exe"; Tasks: desktopicon

[Registry]
; Принудительный запуск от администратора через реестр (совместимость)
Root: HKLM; Subkey: "Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"; ValueType: string; ValueName: "{app}\hwl_vpn.exe"; ValueData: "~ RUNASADMIN"; Flags: uninsdeletevalue

[Files]
; Основные файлы приложения
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; ПУНКТ 2: Visual C++ Redistributable
; Если вы скачали 'vc_redist.x64.exe' и положили его рядом с 'installer.iss', раскомментируйте следующую строку:
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
; ПУНКТ 1: Добавление правил в Firewall (разрешаем входящий трафик для VPN)
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""HWL VPN"" dir=in action=allow program=""{app}\\hwl_vpn.exe"" enable=yes"; Flags: runhidden; StatusMsg: "Adding firewall rules..."

; ПУНКТ 2: Установка Visual C++ (если необходимо и файл добавлен)
; Раскомментируйте строку ниже, если раскомментировали Source выше
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; Check: VCPlusPlusRedistNeedsInstall; StatusMsg: "Installing Visual C++ Redistributable..."

; Запуск приложения
Filename: "{app}\hwl_vpn.exe"; Description: "{cm:LaunchProgram,HWL VPN}"; Flags: nowait postinstall skipifsilent shellexec

[UninstallRun]
; ПУНКТ 1: Удаление правил Firewall при деинсталляции
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""HWL VPN"" program=""{app}\\hwl_vpn.exe"""; Flags: runhidden

[UninstallDelete]
; ПУНКТ 4: Очистка "мусора" (логов и временных файлов), созданных приложением
Type: files; Name: "{app}\*.log"
Type: filesandordirs; Name: "{app}\data"
Type: filesandordirs; Name: "{app}\logs"

[Code]
// ПУНКТ 3: Функция принудительной остановки процессов
procedure TaskKill(FileName: String);
var
  ResultCode: Integer;
begin
    // /F - принудительно, /IM - имя образа, SW_HIDE - скрыть окно консоли
    Exec('taskkill.exe', '/f /im ' + '"' + FileName + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

// Проверка необходимости установки VC++ Redistributable (2015-2022)
function VCPlusPlusRedistNeedsInstall: Boolean;
var
  RegKey: String;
begin
  // Ключ реестра для Visual C++ 2015-2022 (x64)
  RegKey := 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64';
  // Если ключа нет, значит Runtime, скорее всего, не установлен
  Result := not RegKeyExists(HKLM, RegKey);
end;

function InitializeSetup(): Boolean;
begin
  // ПУНКТ 3: Убиваем процессы перед началом установки, чтобы разблокировать файлы
  TaskKill('hwl_vpn.exe');
  TaskKill('sing-box.exe');
  
  // Дополнительная проверка на права администратора (хотя PrivilegesRequired делает это)
  Result := True;
end;