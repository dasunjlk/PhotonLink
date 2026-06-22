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
Built: 2026-06-18 14:46

