#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/python_executables"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

required_bins=(
  filtre
  excel_generator
  black_flake_warning
  autofix
  delete_results
  black
  flake8
  autoflake
  autopep8
)

for bin in "${required_bins[@]}"; do
  if [ ! -x "$BIN_DIR/$bin" ]; then
    echo "Missing executable: $BIN_DIR/$bin" >&2
    exit 1
  fi
done

cat > "$TMP_DIR/test_sample.py" <<'EOF'
import pytest

@pytest.mark.metadata(description="sample")
class TestSample:
    def test_ok(self):
        assert True
EOF

cat > "$TMP_DIR/rules.txt" <<'EOF'
metadata:description;mandatory:yes;type:string;possible values:any
EOF

export PATH="$BIN_DIR:$PATH"

filter_output="$($BIN_DIR/filtre "$TMP_DIR" "$TMP_DIR/rules.txt")"
if [[ "$filter_output" != *"test_sample.py"* ]]; then
  echo "filtre output does not contain expected file." >&2
  echo "$filter_output" >&2
  exit 1
fi

$BIN_DIR/excel_generator "$TMP_DIR" "$TMP_DIR/excel_result.xlsx" "$TMP_DIR/rules.txt"
if [ ! -f "$TMP_DIR/excel_result.xlsx" ]; then
  echo "excel_generator did not create excel_result.xlsx" >&2
  exit 1
fi

$BIN_DIR/black_flake_warning "$TMP_DIR"
if [ ! -f "$TMP_DIR/black_flake_warning.txt" ]; then
  echo "black_flake_warning did not create black_flake_warning.txt" >&2
  exit 1
fi

$BIN_DIR/autofix "$TMP_DIR"
$BIN_DIR/delete_results "$TMP_DIR"

if [ -f "$TMP_DIR/black_flake_warning.txt" ]; then
  echo "delete_results did not remove black_flake_warning.txt" >&2
  exit 1
fi

echo "Linux bundled executable smoke tests passed."