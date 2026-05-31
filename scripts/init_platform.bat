@echo off
REM Initialize missing Flutter platform files without overwriting lib/
cd /d "%~dp0..\photonlink_app"
echo Running flutter create to merge platform scaffolding...
flutter create . --project-name photonlink_app --org com.photonlink
echo.
echo Installing dependencies...
flutter pub get
echo.
echo Running analysis...
flutter analyze
echo.
echo Running tests...
flutter test
echo.
echo Done. Run 'flutter run' to launch the app.
