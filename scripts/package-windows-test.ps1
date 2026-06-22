# Packages PhotonLink for testing on another Windows x64 laptop.
# Usage (PowerShell):
#   cd C:\Users\ASUS\Documents\Projects\PhotonLink
#   powershell -ExecutionPolicy Bypass -File .\scripts\package-windows-test.ps1

$ErrorActionPreference = 'Stop'

$Root = Split-Path $PSScriptRoot -Parent
$AppDir = Join-Path $Root 'photonlink_app'
$CoreDir = Join-Path $Root 'photonlink_core'
$ReleaseDir = Join-Path $AppDir 'build\windows\x64\runner\Release'
$DistDir = Join-Path $Root 'dist\PhotonLink-Windows-x64-test'
$ZipPath = Join-Path $Root 'dist\PhotonLink-Windows-x64-test.zip'
$RustDll = Join-Path $CoreDir 'target\release\photonlink_core.dll'

Write-Host '==> Building Rust core (release)...'
Push-Location $CoreDir
cargo build --release
Pop-Location

Write-Host '==> Building Flutter Windows app (release)...'
Push-Location $AppDir
flutter pub get
flutter build windows --release
Pop-Location

if (-not (Test-Path $ReleaseDir)) {
    throw "Release folder not found: $ReleaseDir"
}

Write-Host '==> Creating distribution folder...'
if (Test-Path $DistDir) { Remove-Item $DistDir -Recurse -Force }
New-Item -ItemType Directory -Path $DistDir | Out-Null
Copy-Item (Join-Path $ReleaseDir '*') $DistDir -Recurse -Force

if (Test-Path $RustDll) {
    Copy-Item $RustDll (Join-Path $DistDir 'photonlink_core.dll') -Force
    Write-Host '    Added photonlink_core.dll'
}

# Flutter docs: bundle MSVC runtime DLLs for machines without VC++ installed.
$VcDlls = @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')
$System32 = Join-Path $env:WINDIR 'System32'
foreach ($name in $VcDlls) {
    $src = Join-Path $System32 $name
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $DistDir $name) -Force
        Write-Host "    Added $name"
    } else {
        Write-Warning "Missing $name on this PC - install Visual Studio Build Tools or VC++ Redistributable."
    }
}

$readme = @'
PhotonLink - Windows test build
================================

HOW TO RUN
1. Copy this ENTIRE folder (or extract the full ZIP) on the test laptop.
2. Do NOT move only photonlink_app.exe - all files must stay together.
3. Double-click photonlink_app.exe

REQUIRED ON THE TEST LAPTOP
- Windows 10/11, 64-bit (x64)
- Webcam for QR / Color Matrix receive (allow camera when prompted)

IF YOU SEE Bad Image / error 0xc0e90002 on a DLL
1. Install Microsoft Visual C++ Redistributable 2015-2022 (x64):
   https://aka.ms/vs/17/release/vc_redist.x64.exe
2. On Windows 11: Windows Security may block unsigned test apps
   (Smart App Control). Try More info then Run anyway.
3. Extract the ZIP again (a partial copy can corrupt DLLs).

FILES IN THIS PACKAGE
- photonlink_app.exe
- photonlink_core.dll (Rust core)
- flutter_windows.dll
- camera_desktop_plugin.dll
- permission_handler_windows_plugin.dll
- msvcp140.dll, vcruntime140.dll, vcruntime140_1.dll (VC++ runtime)
- data\ (required app assets)
'@

$readme += "`r`nBuilt: $(Get-Date -Format 'yyyy-MM-dd HH:mm')`r`n"

Set-Content -Path (Join-Path $DistDir 'README.txt') -Value $readme -Encoding UTF8

Write-Host '==> Creating ZIP...'
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path (Join-Path $DistDir '*') -DestinationPath $ZipPath -Force

$zipMb = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
Write-Host ''
Write-Host "Done."
Write-Host "Folder: $DistDir"
Write-Host ('ZIP:    {0} ({1} MB)' -f $ZipPath, $zipMb)
