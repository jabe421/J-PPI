#define AppName "J-PPI"

[Setup]
AppId={{A38EF120-CEB9-4552-B387-00957A33456D}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Jabe
AppPublisherURL=https://github.com/jabe421/J-PPI
AppUpdatesURL=https://github.com/jabe421/J-PPI/releases
DefaultDirName={localappdata}\Programs\J-PPI
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\J-PPI.ico
SetupIconFile=J-PPI.ico
LicenseFile=LICENSE
OutputDir=artifacts
OutputBaseFilename=J-PPI-Windows-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "startmenu"; Description: "Create a Start menu shortcut"
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "J-PPI.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "J-PPI-splash.png"; DestDir: "{app}"; Flags: ignoreversion
Source: "PlexPlaylistCreator.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "New-PlexPlaylist.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "PlexMusicLibraries.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "RELEASE-NOTES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "USER-GUIDE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userprograms}\J-PPI"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -STA -WindowStyle Hidden -File ""{app}\PlexPlaylistCreator.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\J-PPI.ico"; Tasks: startmenu
Name: "{userdesktop}\J-PPI"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -STA -WindowStyle Hidden -File ""{app}\PlexPlaylistCreator.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\J-PPI.ico"; Tasks: desktopicon

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -STA -WindowStyle Hidden -File ""{app}\PlexPlaylistCreator.ps1"""; WorkingDir: "{app}"; Description: "Launch J-PPI"; Flags: nowait postinstall skipifsilent
