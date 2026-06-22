@echo off
REM Build and zip PhotonLink for Windows x64 testing.
REM Run from any folder:
REM   C:\Users\ASUS\Documents\Projects\PhotonLink\scripts\package-windows-test.cmd

set ROOT=%~dp0..
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\package-windows-test.ps1"
if errorlevel 1 exit /b 1
pause
