import 'dart:io';

import 'package:path/path.dart' as path;

class PythonRunner {
  static String resolveExecutableDirectory() {
    return path.join(path.dirname(Platform.resolvedExecutable), 'python_executables');
  }

  static String resolveExecutablePath(String scriptName) {
    final executableName = path.basenameWithoutExtension(scriptName);
    return path.join(resolveExecutableDirectory(), executableName);
  }

  static Future<ProcessResult> runBundledExecutable(String scriptName, List<String> args) async {
    final executablePath = resolveExecutablePath(scriptName);
    final executableFile = File(executablePath);

    if (!executableFile.existsSync()) {
      throw FileSystemException(
        'Bundled executable not found. Run code_python/build_linux.sh before building the Linux app release and make sure python_executables/ is shipped with the bundle.',
        executablePath,
      );
    }

    final executableDirectory = path.dirname(executablePath);
    final environment = Map<String, String>.from(Platform.environment);
    final existingPath = environment['PATH'];
    environment['PATH'] = existingPath == null || existingPath.isEmpty
        ? executableDirectory
        : '$executableDirectory${Platform.isWindows ? ';' : ':'}$existingPath';

    return Process.run(
      executablePath,
      args,
      workingDirectory: executableDirectory,
      runInShell: false,
      environment: environment,
    );
  }
}