@echo off
REM Register draqosd as a logon scheduled task (user scope, no admin).
REM Usage: register_daemon.bat "C:\path\to\draqosd.exe"
schtasks /create /tn DRAQOS-daemon /tr "\"%~1\"" /sc onlogon /rl limited /f
