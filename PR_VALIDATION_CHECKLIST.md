# Post-CI Validation Checklist

This checklist helps verify that the PR is ready to merge once GitHub Actions CI completes.

## GitHub Actions CI Results

Once the PR is created, GitHub Actions will run the `linux-ubuntu-bundle-smoke` workflow automatically.

### Expected CI Status: ✅ All checks pass

**Workflow: `linux-ubuntu-bundle-smoke`**

Steps the CI runs (you can monitor on GitHub):

- [ ] **Checkout** - Repository cloned
- [ ] **Set up Python 3.11** - Python environment installed
- [ ] **Set up Flutter** - Flutter SDK installed on ubuntu-latest
- [ ] **Flutter pub get** - Dependencies installed
- [ ] **Build bundled Python executables** - `code_python/build_linux.sh` runs without errors
- [ ] **Run bundled executable smoke tests** - `code_python/smoke_test_linux_binaries.sh` passes
- [ ] **Build Linux release** - `flutter build linux --release` succeeds
- [ ] **Verify executables in release bundle** - All 5 binaries found with execute permission

**CI is considered ✅ PASS** if all steps complete without errors.

---

## Local Validation Before Merge

Even if CI passes, validate locally on an Ubuntu machine:

### 1. Clone and Test on Build Machine

```bash
git clone https://github.com/king-wassim/desktop-app-ubuntu.git
cd desktop-app-ubuntu
git checkout feature/bundle-python-linux

# Run automated test script
bash test_linux_bundle.sh
```

**Expected output:**
```
✅ All validation checks PASSED
```

- [ ] Build script completes without errors
- [ ] All executables created with `chmod +x`
- [ ] Smoke tests pass
- [ ] Flutter release builds successfully
- [ ] Release bundle contains all 5 executables

### 2. Test on Clean Ubuntu Machine (No Python)

**Prerequisites:**
- Fresh Ubuntu 20.04+ VM or machine
- NO Python installed (`which python3` returns nothing)

**Steps:**

```bash
# Copy the release bundle
scp -r <build-machine>:path/to/desktop-app-ubuntu/build/linux/x64/release/bundle .

# Enter the bundle directory
cd bundle

# Verify no Python
which python3  # should say: not found

# Run the app
./desktop_app
```

**Expected behavior:**

- [ ] App launches without "Python not found" error
- [ ] UI appears (green gradient, KPIT logo)
- [ ] No Python processes running (`ps aux | grep python` shows nothing except grep)

### 3. Functional Tests on Clean Ubuntu

With the app running:

- [ ] **Filter**: Select folder → click Filter → shows file count (no "executable not found" errors)
- [ ] **Excel Generator**: Click Excel Generator → "✅ completed successfully"
- [ ] **Black/Flake**: Click Black/Flake → "✅ completed successfully", creates warning file
- [ ] **Autofix**: Click Autofix → "✅ completed successfully"
- [ ] **Delete Results**: Click Delete Results → "✅ completed successfully", removes warning file

---

## Code Review Checklist

Before merging, verify code quality:

### New Files

- [ ] `code_python/build_linux.sh` - Shell script is executable and syntax-correct
- [ ] `code_python/requirements.txt` - Contains all Python dependencies (pyinstaller, openpyxl, autoflake, autopep8, black, flake8)
- [ ] `code_python/smoke_test_linux_binaries.sh` - Smoke tests work locally
- [ ] `lib/services/python_runner.dart` - Bundles executable path resolution logic, correct error messages
- [ ] `.github/workflows/linux-ubuntu-bundle-smoke.yml` - Workflow is well-formed YAML
- [ ] `TESTING_UBUNTU_BUNDLE.md` - Clear test guide created
- [ ] `test_linux_bundle.sh` - Automated test script

### Modified Files

- [ ] `lib/main.dart` - Uses `PythonRunner` on Linux, preserves non-Linux paths
- [ ] `linux/CMakeLists.txt` - Pre-build hook runs build script, fails gracefully if missing
- [ ] `README.md` - Updated with new Linux workflow (no Python required for end users)
- [ ] `.gitignore` - Excludes `.venv/`, `.pyinstaller-build/`, `python_executables/`

### No Regressions

- [ ] Windows builds still use system Python (if Windows is supported)
- [ ] macOS builds not affected (no macOS changes)
- [ ] Android/iOS builds not affected
- [ ] Dart analysis passes (`flutter analyze`)
- [ ] All imports in `lib/main.dart` and `lib/services/python_runner.dart` are valid

---

## Merge Decision

**Ready to Merge if:**

- ✅ GitHub Actions CI passes
- ✅ Local test script passes
- ✅ Functional tests pass on clean Ubuntu (no Python)
- ✅ All code review items checked
- ✅ No regressions on other platforms

**Do NOT merge if:**

- ❌ CI fails (especially smoke tests)
- ❌ App crashes on clean Ubuntu without Python
- ❌ Any analysis function fails on clean Ubuntu
- ❌ Python processes run when they shouldn't
- ❌ Dart analysis shows errors

---

## Post-Merge Steps

Once PR is merged to `main`:

1. **Tag a release** (e.g., `v2.0.0-linux-bundled`)
   ```bash
   git tag v2.0.0-linux-bundled
   git push origin v2.0.0-linux-bundled
   ```

2. **Create a GitHub Release** with the bundle:
   ```bash
   cd build/linux/x64/release/bundle
   tar czf desktop-app-ubuntu-v2.0.0-linux-bundled.tar.gz .
   # Upload to GitHub Releases
   ```

3. **Update documentation** with the new release link

4. **Announce** that Ubuntu/Linux version no longer requires Python installation

---

## Questions During Testing?

If you encounter issues:

1. Check the debug output: `flutter run -d linux` (look for `[DEBUG]` messages)
2. Check CMake logs during build: `flutter build linux --release -v`
3. Verify executables are executable: `file build/linux/x64/release/bundle/python_executables/*`
4. Check if binaries are ELF format: `file build/linux/x64/release/bundle/python_executables/filtre`

---

## Success Criteria Summary

| Criterion | Status |
|-----------|--------|
| CI smoke tests pass | ✅ |
| Local build script succeeds | ✅ |
| All 5 executables created | ✅ |
| App runs on clean Ubuntu (no Python) | ✅ |
| All 5 functions work (filter, excel, black, autofix, delete) | ✅ |
| No Python processes while app runs | ✅ |
| No regressions on other platforms | ✅ |

---

**Once all checks pass: Ready for Release!** 🚀
