# Testing the Linux Bundle Executables (Ubuntu)

This document provides a comprehensive guide to validate that the bundled Python executables work correctly on a clean Ubuntu machine without Python installed.

## Prerequisites

### On your Ubuntu test machine:
- Ubuntu 20.04 LTS or later
- Flutter SDK installed
- **NO Python** installed (or uninstalled before testing)
- Git

### What you're testing:
- Building bundled Python executables via `code_python/build_linux.sh`
- Running the Flutter app in debug mode on Linux
- Running the Flutter release build with bundled executables
- Verifying all 5 analysis functions work (filtre, excel, black/flake, autofix, delete)

---

## Step 1: Clone the Repository and Switch to Feature Branch

```bash
git clone https://github.com/king-wassim/desktop-app-ubuntu.git
cd desktop-app-ubuntu
git checkout feature/bundle-python-linux
```

---

## Step 2: Install Python and Build Dependencies (for the build machine only, NOT the test machine)

**On the machine where you BUILD the app**, install Python and build tools:

```bash
sudo apt update
sudo apt install python3 python3-venv python3-pip
```

**On a CLEAN test machine (no Python)**, skip this and test with the pre-built release bundle.

---

## Step 3: Build Bundled Python Executables

From the repository root:

```bash
cd code_python
chmod +x build_linux.sh
bash build_linux.sh
```

This should output:
```
Built executables in: /path/to/code_python/python_executables
```

Verify files were created:

```bash
ls -la code_python/python_executables/
```

You should see:
```
filtre
excel_generator
black_flake_warning
autofix
delete_results
black
flake8
autoflake
autopep8
```

All should be executable (`-rwxr-xr-x`).

---

## Step 4: Run Smoke Tests (Optional, on the build machine)

```bash
cd code_python
chmod +x smoke_test_linux_binaries.sh
bash smoke_test_linux_binaries.sh
```

Expected output:
```
Linux bundled executable smoke tests passed.
```

---

## Step 5: Build Flutter Linux Release

From the repository root:

```bash
flutter pub get
flutter build linux --release
```

The build will:
1. Run `code_python/build_linux.sh` automatically (via CMake pre-build hook)
2. Build the Flutter app
3. Package the release with executables in: `build/linux/x64/release/bundle/python_executables/`

Verify the executables are in the bundle:

```bash
ls -la build/linux/x64/release/bundle/python_executables/
```

---

## Step 6: Test on a Clean Ubuntu Machine (No Python)

### 6a. Copy the release bundle to the clean machine

```bash
# On build machine:
tar czf desktop_app_release.tar.gz build/linux/x64/release/bundle/

# Transfer to clean test machine and extract:
tar xzf desktop_app_release.tar.gz
```

### 6b. Verify executables exist

```bash
ls -la build/linux/x64/release/bundle/python_executables/
```

### 6c. Verify Python is NOT installed

```bash
which python3
# Should output: not found

python3 --version
# Should output: command not found
```

### 6d. Run the app

```bash
build/linux/x64/release/bundle/desktop_app
```

The app should launch with the UI. If Python were missing, it would error immediately.

---

## Step 7: Test All Analysis Functions

With the app running on the clean test machine:

### 7a. Test Filter (filtre.py)

1. Click **"Import Folder"** and select a folder with Python test files (e.g., `test_*.py`)
2. Click **"Import rules"** and select a rules file (if available)
3. Click **"Filter"**
   - Should show: "X filtered files" message
   - If it says "❌ Bundled executable not found", the bundle is broken

### 7b. Test Excel Generator (excel_generator.py)

1. Ensure folder is selected
2. Click **"Excel Generator"**
   - Should show: "✅ completed successfully"
   - Creates an Excel file with metadata extraction

### 7c. Test Black/Flake8 (black_flake_warning.py)

1. Ensure folder is selected
2. Click **"Black/Flake"**
   - Should show: "✅ completed successfully"
   - Creates a `black_flake_warning.txt` file in the test folder

### 7d. Test Autofix (autofix.py)

1. Ensure folder is selected
2. Click **"Autofix"**
   - Should show: "✅ completed successfully"
   - Fixes Python formatting issues in test files

### 7e. Test Delete Results (delete_results.py)

1. Ensure folder is selected (that has a `black_flake_warning.txt` from step 7c)
2. Click **"Delete results"**
   - Should show: "✅ completed successfully"
   - The `black_flake_warning.txt` file should be removed

---

## Step 8: Verify No Python is Used

Open the app terminal and check for Python processes:

```bash
# On another terminal while app is running:
ps aux | grep -i python
# Should show nothing (except grep itself)
```

If Python processes appear, the app is NOT using bundled executables correctly.

---

## Step 9: Check Debug Logs

While running the app, you can view debug output:

```bash
# Build debug mode with logs
flutter run -d linux

# Watch the terminal for [DEBUG] messages showing:
# [DEBUG] Running bundled executable: /path/to/python_executables/filtre
```

---

## Expected Behavior Summary

| Action | Expected Result |
|--------|-----------------|
| Import folder with test files | ✅ UI responds, no errors |
| Filter | ✅ Shows filtered files list, no Python errors |
| Excel Generator | ✅ Creates Excel file, success message |
| Black/Flake | ✅ Creates warning file, success message |
| Autofix | ✅ Formats Python files, success message |
| Delete Results | ✅ Removes warning file, success message |
| App on clean Ubuntu (no Python) | ✅ All functions work without installing Python |

---

## Troubleshooting

### "Bundled executable not found" error

**Cause:** The `python_executables/` folder is missing from the release bundle.

**Fix:**
```bash
cd code_python
bash build_linux.sh
cd ..
flutter build linux --release
```

### "Permission denied" when running app

**Fix:**
```bash
chmod +x build/linux/x64/release/bundle/python_executables/*
chmod +x build/linux/x64/release/bundle/desktop_app
```

### Smoke tests fail

**Check:**
```bash
cd code_python
bash smoke_test_linux_binaries.sh
```

**Common issues:**
- PyInstaller failed to create binaries (check Python deps)
- Test files don't have `pytest.mark.metadata` decorator

---

## Success Criteria

✅ All tests pass (filter, excel, black, autofix, delete)
✅ No Python processes running while app is active
✅ Release bundle runs on clean Ubuntu without Python installed
✅ All UI messages show "✅ completed successfully"

---

## Next Steps

1. Run this test guide locally on Ubuntu
2. Open the PR and let GitHub Actions smoke tests run (duplicate validation)
3. Merge PR once both local and CI tests pass
4. Close GitHub issue (if applicable)

