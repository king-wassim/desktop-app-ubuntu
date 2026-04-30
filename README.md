# Desktop App (Ubuntu)

A Flutter desktop application for Ubuntu/Linux that runs Python-based code analysis.

## Overview

This project combines:

- **Flutter (Dart)** for the Linux desktop UI
- **Bundled Python-based analyzers** for the code checks and fixes used by the app

The Flutter app launches bundled executables, exchanges data via **JSON** (stdout/stderr), and displays results in the UI.

## Download / Run

If you have a built release:

1. Download the Linux build
2. Run the application binary

## Python requirement

On **Ubuntu/Linux**, no Python installation is required for end users.

- The app runs standalone executables stored in `python_executables/`
- Those executables are bundled next to the Linux app binary in release builds
- If the bundle is missing the executables, the app will show a clear error telling you to rebuild them

## Development

### Prerequisites

- Flutter SDK installed
- Linux desktop requirements for Flutter (Ubuntu)
- Python 3 only if you are rebuilding the bundled executables locally

If you are rebuilding the executables on Ubuntu, install the build-time Python packages first:

```bash
sudo apt update
sudo apt install python3 python3-venv python3-pip
```

### Run locally

```bash
flutter pub get
flutter run -d linux
```

### Rebuild bundled Python executables

From the repository root:

```bash
cd code_python
bash build_linux.sh
```

This script creates a virtual environment, installs the Python dependencies from `requirements.txt`, and writes the executables to `code_python/python_executables/`.

### Build (release)

The Linux build now runs `code_python/build_linux.sh` automatically during the Linux CMake build.

Manual build remains useful for local validation:

```bash
cd code_python
bash build_linux.sh
cd ..
flutter build linux --release
```

The release bundle will include `python_executables/` next to the app binary, for example:

```text
build/linux/x64/release/bundle/python_executables/
```

The app resolves that folder relative to its own executable at runtime, so the release can run on a clean Ubuntu machine without Python installed.

### Packaging notes

- Keep `code_python/python_executables/` out of version control; regenerate it when the Python scripts change
- The Linux build fails if Python executable bundling fails, so a broken release cannot be produced

### Ubuntu smoke test

On Ubuntu CI and local Ubuntu environments you can run:

```bash
cd code_python
bash smoke_test_linux_binaries.sh
```

This validates that the bundled binaries execute correctly (filter, excel, warnings, autofix, cleanup).

## Python integration

- Python sources live in `code_python/`
- The Linux app runs the bundled executables directly through `Process.run(executablePath, args, ...)`
- JSON stdout/stderr behavior is preserved, so the Flutter UI can keep parsing script output the same way

### Runtime location

The Linux app looks for executables relative to its own binary, not `Directory.current`.

At runtime the expected structure is:

```text
bundle/
	desktop_app
	python_executables/
```

## Project structure (high level)

- `lib/` — Flutter app source code
- `code_python/` — Python scripts
- `linux/` — Linux runner and build files

## License

This project is currently not licensed. All rights reserved.
