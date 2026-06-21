@echo off
title Diaro Release Publisher
echo.
echo =========================================================
echo               Diaro GitHub Release Publisher
echo =========================================================
echo.
echo Step 1: Authenticating with GitHub CLI...
"C:\Program Files\GitHub CLI\gh.exe" auth login
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Authentication failed. Please try again.
    pause
    exit /b
)
echo.
echo Step 2: Creating and pushing git tag v1.0.0...
git tag v1.0.0
git push origin v1.0.0
if %errorlevel% neq 0 (
    echo.
    echo [WARNING] Tag already exists on remote or push failed. Continuing to release creation...
)
echo.
echo Step 3: Creating GitHub Release and uploading APK...
"C:\Program Files\GitHub CLI\gh.exe" release create v1.0.0 "public/app-release.apk" --title "Diaro v1.0.0 - Initial Public Release" --notes-file "C:\Users\yochi\.gemini\antigravity-ide\brain\6fb83060-32de-4ab3-8b8e-eb8511d3ba27\release-notes.md"
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to create release.
    pause
    exit /b
)
echo.
echo =========================================================
echo   🎉 Release published successfully!
echo   Page URL: https://github.com/yochitcheedella/YNotes/releases/tag/v1.0.0
echo   Direct APK: https://github.com/yochitcheedella/YNotes/releases/download/v1.0.0/app-release.apk
echo =========================================================
echo.
pause
