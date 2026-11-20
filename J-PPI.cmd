@echo off
powershell.exe -NoProfile -STA -File "%~dp0PlexPlaylistCreator.ps1"
if errorlevel 1 pause
