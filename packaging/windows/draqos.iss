; DRAQOS Windows installer (Inno Setup 6).
; Built on the release workflow after `flutter build windows` and
; `dart compile exe ... -o build/draqosd.exe`.
; Registers draqosd to start at logon via a scheduled task (user scope).

#define AppVer GetEnv("AppVersion")
#if AppVer == ""
  #define AppVer "0.1.0"
#endif

[Setup]
AppName=DRAQOS
AppVersion={#AppVer}
AppPublisher=DRAQOS contributors
DefaultDirName={autopf}\DRAQOS
OutputBaseFilename=draqos-{#AppVer}-windows-setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest

[Files]
Source: "..\..\apps\draqos_app\build\windows\x64\runner\Release\*"; DestDir: "{app}\app"; Flags: recursesubdirs
Source: "..\..\build\draqosd.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\DRAQOS"; Filename: "{app}\app\draqos_app.exe"
Name: "{autodesktop}\DRAQOS"; Filename: "{app}\app\draqos_app.exe"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; Flags: unchecked
Name: autostart; Description: "Start draqosd at logon"; Flags: unchecked

[Run]
; Scheduled logon task running the daemon (user scope, no admin needed).
Filename: "schtasks"; Parameters: "/create /tn DRAQOS-daemon /tr ""\"{app}\draqosd.exe""" /sc onlogon /rl limited /f"; Flags: runhidden; Tasks: autostart
Filename: "{app}\app\draqos_app.exe"; Description: "Launch DRAQOS"; Flags: postinstall nowait skipifsilent

[UninstallRun]
Filename: "schtasks"; Parameters: "/delete /tn DRAQOS-daemon /f"; Flags: runhidden
