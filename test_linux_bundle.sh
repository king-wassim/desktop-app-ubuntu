#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
BUILD_SUMMARY="$REPO_ROOT/BUILD_TEST_SUMMARY.txt"

echo "=============================================="
echo "Ubuntu Bundle End-to-End Validation Suite"
echo "=============================================="
echo ""

{
  echo "Build Summary - $(date)"
  echo "========================================"
  echo ""

  # Check prerequisites
  echo "1. Checking prerequisites..."
  if ! command -v flutter >/dev/null 2>&1; then
    echo "ERROR: Flutter not found. Install Flutter SDK first."
    exit 1
  fi
  echo "✓ Flutter: $(flutter --version | head -1)"

  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: Git not found."
    exit 1
  fi
  echo "✓ Git: $(git --version)"

  if ! command -v python3 >/dev/null 2>&1; then
    echo "WARNING: Python3 not found. Build will fail. Install python3-venv and run: sudo apt install python3 python3-venv python3-pip"
    exit 1
  fi
  echo "✓ Python3: $(python3 --version)"

  echo ""
  echo "2. Building bundled Python executables..."
  cd "$REPO_ROOT/code_python"
  if [ ! -x "build_linux.sh" ]; then
    chmod +x build_linux.sh
  fi
  bash build_linux.sh 2>&1 | tee -a "$BUILD_SUMMARY"
  echo "✓ Executables built"

  echo ""
  echo "3. Running smoke tests..."
  if [ ! -x "smoke_test_linux_binaries.sh" ]; then
    chmod +x smoke_test_linux_binaries.sh
  fi
  bash smoke_test_linux_binaries.sh 2>&1 | tee -a "$BUILD_SUMMARY"
  echo "✓ Smoke tests passed"

  echo ""
  echo "4. Building Flutter Linux release..."
  cd "$REPO_ROOT"
  flutter pub get >/dev/null 2>&1
  flutter build linux --release 2>&1 | tee -a "$BUILD_SUMMARY"
  echo "✓ Flutter release built"

  echo ""
  echo "5. Verifying executables in release bundle..."
  BUNDLE_DIR="$REPO_ROOT/build/linux/x64/release/bundle"
  EXEC_DIR="$BUNDLE_DIR/python_executables"

  if [ ! -d "$EXEC_DIR" ]; then
    echo "ERROR: python_executables directory not found in bundle."
    exit 1
  fi

  required_bins=(
    filtre
    excel_generator
    black_flake_warning
    autofix
    delete_results
  )

  for bin in "${required_bins[@]}"; do
    if [ ! -x "$EXEC_DIR/$bin" ]; then
      echo "ERROR: Missing executable: $EXEC_DIR/$bin"
      exit 1
    fi
    echo "✓ Found: $bin"
  done

  echo ""
  echo "6. Checking app binary..."
  APP_BIN="$BUNDLE_DIR/desktop_app"
  if [ ! -x "$APP_BIN" ]; then
    echo "ERROR: App binary not found: $APP_BIN"
    exit 1
  fi
  echo "✓ App binary: $APP_BIN"

  echo ""
  echo "=============================================="
  echo "✅ All validation checks PASSED"
  echo "=============================================="
  echo ""
  echo "Next steps:"
  echo "1. Create PR: https://github.com/king-wassim/desktop-app-ubuntu/pull/new/feature/bundle-python-linux"
  echo "2. Wait for GitHub Actions to run smoke tests on ubuntu-latest"
  echo "3. On a clean Ubuntu machine (no Python installed):"
  echo "   cd build/linux/x64/release/bundle"
  echo "   ./desktop_app"
  echo ""
  echo "Release bundle location: $BUNDLE_DIR"
  echo "Test instructions: see TESTING_UBUNTU_BUNDLE.md"
  echo ""

} | tee -a "$BUILD_SUMMARY"
