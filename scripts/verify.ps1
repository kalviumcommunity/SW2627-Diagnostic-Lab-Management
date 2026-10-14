# ==============================================================================
# Local CI/CD Pre-Push Verification Script (PowerShell)
# Simulates the complete GitHub Actions CI pipeline locally.
# ==============================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "🚀 Running LabTrack Local CI/CD Verification Pipeline" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$RepoRoot = Split-Path -Parent $PSScriptRoot
$LabTrackDir = Join-Path $RepoRoot "lab_track"

Set-Location $LabTrackDir

# Step 1: Install Dependencies
Write-Host "`n📦 [1/4] Resolving Flutter Dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to resolve dependencies!" -ForegroundColor Red
    exit 1
}

# Step 2: Static Analysis
Write-Host "`n🔍 [2/4] Running Static Analysis (Zero Errors & Warnings)..." -ForegroundColor Yellow
flutter analyze --fatal-warnings
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Static analysis failed! Fix syntax or type errors before pushing." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Static analysis passed with zero errors/warnings!" -ForegroundColor Green

# Step 3: Unit & Widget Tests
Write-Host "`n🧪 [3/4] Running Flutter Tests..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter tests failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ All tests passed!" -ForegroundColor Green

# Step 4: Web Compilation
Write-Host "`n🌐 [4/4] Compiling Flutter Web for Chrome..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter web compilation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flutter web build succeeded!" -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "🎉 ALL CI/CD CHECKS PASSED! Ready to commit and push PR." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
