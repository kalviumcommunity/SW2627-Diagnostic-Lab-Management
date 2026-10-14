#!/usr/bin/env bash
# ==============================================================================
# Local CI/CD Pre-Push Verification Script (Bash)
# Simulates the complete GitHub Actions CI pipeline locally.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LAB_TRACK_DIR="$REPO_ROOT/lab_track"

echo -e "\033[1;36m==========================================================\033[0m"
echo -e "\033[1;36m🚀 Running LabTrack Local CI/CD Verification Pipeline\033[0m"
echo -e "\033[1;36m==========================================================\033[0m"

cd "$LAB_TRACK_DIR"

echo -e "\n\033[1;33m📦 [1/4] Resolving Flutter Dependencies...\033[0m"
flutter pub get

echo -e "\n\033[1;33m🔍 [2/4] Running Static Analysis (Zero Errors & Warnings)...\033[0m"
flutter analyze --fatal-warnings
echo -e "\033[1;32m✅ Static analysis passed with zero errors/warnings!\033[0m"

echo -e "\n\033[1;33m🧪 [3/4] Running Flutter Tests...\033[0m"
flutter test
echo -e "\033[1;32m✅ All tests passed!\033[0m"

echo -e "\n\033[1;33m🌐 [4/4] Compiling Flutter Web for Chrome...\033[0m"
flutter build web --release
echo -e "\033[1;32m✅ Flutter web build succeeded!\033[0m"

echo -e "\n\033[1;36m==========================================================\033[0m"
echo -e "\033[1;32m🎉 ALL CI/CD CHECKS PASSED! Ready to commit and push PR.\033[0m"
echo -e "\033[1;36m==========================================================\033[0m"
