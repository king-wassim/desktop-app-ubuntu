#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
OUTPUT_DIR="$SCRIPT_DIR/python_executables"
BUILD_DIR="$SCRIPT_DIR/.pyinstaller-build"
WRAPPER_DIR="$(mktemp -d)"
PYTHON_BIN="$VENV_DIR/bin/python"
PYINSTALLER_BIN="$VENV_DIR/bin/pyinstaller"

cleanup() {
  rm -rf "$WRAPPER_DIR"
}

trap cleanup EXIT

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to build the Linux executables." >&2
  exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi

"$PYTHON_BIN" -m pip install --upgrade pip
"$PYTHON_BIN" -m pip install -r "$SCRIPT_DIR/requirements.txt"

mkdir -p "$OUTPUT_DIR" "$BUILD_DIR"

build_script() {
  local script_file="$1"
  local binary_name="$2"
  "$PYINSTALLER_BIN" \
    --noconfirm \
    --clean \
    --onefile \
    --name "$binary_name" \
    --distpath "$OUTPUT_DIR" \
    --workpath "$BUILD_DIR/$binary_name" \
    --specpath "$BUILD_DIR/specs" \
    "$SCRIPT_DIR/$script_file"
}

write_wrapper() {
  local wrapper_file="$1"
  local module_name="$2"
  cat > "$WRAPPER_DIR/$wrapper_file" <<EOF
import runpy

runpy.run_module("$module_name", run_name="__main__")
EOF
}

build_module_wrapper() {
  local wrapper_file="$1"
  local binary_name="$2"
  local module_name="$3"

  write_wrapper "$wrapper_file" "$module_name"
  "$PYINSTALLER_BIN" \
    --noconfirm \
    --clean \
    --onefile \
    --name "$binary_name" \
    --collect-all "$module_name" \
    --distpath "$OUTPUT_DIR" \
    --workpath "$BUILD_DIR/$binary_name" \
    --specpath "$BUILD_DIR/specs" \
    "$WRAPPER_DIR/$wrapper_file"
}

build_script "filtre.py" "filtre"
build_script "excel_generator.py" "excel_generator"
build_script "black_flake_warning.py" "black_flake_warning"
build_script "autofix.py" "autofix"
build_script "delete_results.py" "delete_results"

build_module_wrapper "black_wrapper.py" "black" "black"
build_module_wrapper "flake8_wrapper.py" "flake8" "flake8"
build_module_wrapper "autoflake_wrapper.py" "autoflake" "autoflake"
build_module_wrapper "autopep8_wrapper.py" "autopep8" "autopep8"

chmod +x "$OUTPUT_DIR"/*

echo "Built executables in: $OUTPUT_DIR"