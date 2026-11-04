# LabTrack Ultra-Fast Android APK Builder
param(
    [switch]$Install,
    [switch]$Debug
)

$sw = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Building LabTrack APK (Target: android-arm64)..." -ForegroundColor Cyan

$buildType = if ($Debug) { "--debug" } else { "--release" }
$apkSource = if ($Debug) { 
    "build\app\outputs\flutter-apk\app-debug.apk" 
} else { 
    "build\app\outputs\flutter-apk\app-release.apk" 
}

# Compile specifically for arm64 (99% of Android phones), skipping unused architectures
flutter build apk $buildType --target-platform android-arm64 --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Copy to accessible output folder
$outputDest = "..\output\LabTrack-fast.apk"
if (-not (Test-Path "..\output")) { 
    New-Item -ItemType Directory -Path "..\output" -Force | Out-Null 
}
Copy-Item $apkSource $outputDest -Force
Copy-Item $apkSource "..\output\LabTrack-release.apk" -Force

$sw.Stop()
$elapsed = [math]::Round($sw.Elapsed.TotalSeconds, 1)

Write-Host "APK ready in $elapsed seconds!" -ForegroundColor Green
Write-Host "File: $outputDest" -ForegroundColor White

if ($Install) {
    Write-Host "Installing to connected device via ADB..." -ForegroundColor Yellow
    adb install -r $outputDest
}
