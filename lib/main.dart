import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import 'dart:ui' as ui;
import 'services/python_runner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    center: true,
    minimumSize: Size(800, 600),
    title: "",
    backgroundColor: Colors.green,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await Future.delayed(const Duration(milliseconds: 100));
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const MetadataApp());
}

class MetadataApp extends StatelessWidget {
  const MetadataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color.fromARGB(255, 27, 111, 24),
        scaffoldBackgroundColor: const Color.fromARGB(255, 27, 111, 24),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 27, 111, 24),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 27, 111, 24),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? oldFolderPath;
  String? folderPath;
  String? rulesPath;
  List<String> oldPythonFiles = [];
  List<String> pythonFiles = [];
  bool isLoading = false;
  bool filterApplied = false;

  List<String> _getTestPythonFiles(String folderPath) {
    final dir = Directory(folderPath);
    final files = <String>[];
    for (final file in dir.listSync(recursive: true)) {
      if (file is File &&
          file.path.endsWith('.py') &&
          file.uri.pathSegments.last.startsWith('test')) {
        files.add(file.path);
      }
    }
    return files;
  }

  Future<String> _getPythonCommand() async {
    final List<String> pythonCommands = ['python3', 'python', 'python3.8', 'python3.9', 'python3.10', 'python3.11', 'python3.12'];
    
    for (String cmd in pythonCommands) {
      try {
        final result = await Process.run(cmd, ['--version'], runInShell: true);
        if (result.exitCode == 0) {
          print('[DEBUG] Found Python: $cmd - ${result.stdout}');
          return cmd;
        }
      } catch (e) {
        continue;
      }
    }
    
    final List<String> commonPaths = [
      '/usr/bin/python3',
      '/usr/bin/python',
      '/usr/local/bin/python3',
      '/usr/local/bin/python',
      '/bin/python3',
      '/bin/python'
    ];
    
    for (String pythonPath in commonPaths) {
      try {
        final result = await Process.run(pythonPath, ['--version'], runInShell: true);
        if (result.exitCode == 0) {
          print('[DEBUG] Found Python at: $pythonPath - ${result.stdout}');
          return pythonPath;
        }
      } catch (e) {
        continue;
      }
    }
    
    throw Exception('Python not found. Please install Python using: sudo apt update && sudo apt install python3 python3-pip');
  }

  Future<ProcessResult?> _runPythonScript(String scriptName, List<String> args, BuildContext context) async {
    setState(() => isLoading = true);

    try {
      late final ProcessResult result;

      if (Platform.isLinux) {
        result = await PythonRunner.runBundledExecutable(scriptName, args);
        print('[DEBUG] Running bundled executable: ${PythonRunner.resolveExecutablePath(scriptName)} with args: $args');
      } else {
        final pythonCmd = await _getPythonCommand();
        final workingDir = path.join(Directory.current.path, 'code_python');
        final scriptPath = path.join(workingDir, scriptName);

        if (!Directory(workingDir).existsSync()) {
          throw Exception('Working directory not found: $workingDir\nPlease ensure the code_python folder exists in your app directory.');
        }

        if (!File(scriptPath).existsSync()) {
          throw Exception('Script not found: $scriptPath\nPlease ensure $scriptName exists in the code_python folder.');
        }

        print('[DEBUG] Running: $pythonCmd $scriptName with args: $args');
        print('[DEBUG] Working directory: $workingDir');

        result = await Process.run(
          pythonCmd,
          [scriptName, ...args],
          workingDirectory: workingDir,
          runInShell: true,
          environment: {
            ...Platform.environment,
            'PYTHONPATH': workingDir,
          },
        );
      }

      print('[DEBUG] Exit code: ${result.exitCode}');
      print('[DEBUG] Stdout: ${result.stdout}');
      print('[DEBUG] Stderr: ${result.stderr}');

      if (result.exitCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ completed successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error (${scriptName}) : ${result.stderr}"),
            backgroundColor: Colors.red,
          ),
        );
      }

      return result;
    } catch (e) {
      print('[DEBUG] Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 15, 68, 29),
              Color.fromARGB(255, 27, 93, 66),
              Color.fromARGB(255, 46, 132, 59),
              Color.fromARGB(255, 74, 167, 111),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'KPIT',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 66, 232, 107),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Python File Analyzer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _button1(context),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            folderPath == null
                                ? "No folder selected"
                                : "${oldPythonFiles.length} files found",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            _button2(context),
                          ],
                        ),
                        Column(
                          children: [
                            _button3(context),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                !filterApplied
                                    ? "filter is not yet applied"
                                    : (pythonFiles.isEmpty
                                    ? "0 files filtered"
                                    : "${pythonFiles.length} files filtered "),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            _button4(context)
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_button5(context)],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [_button6(context), _button7(context), _button8(context)],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 5,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color.fromARGB(255, 66, 232, 107),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: const Color.fromARGB(255, 66, 232, 107),
                content: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    children: [
                      const TextSpan(text: "Created by "),
                      TextSpan(
                        text: "Chouayakh Wassim",
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final url = Uri.parse("https://www.linkedin.com/in/wassim-chouayakh-174534178/");
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              print("Impossible d'ouvrir $url");
                            }
                          },
                      ),
                      const TextSpan(text: "\nhope you like it!"),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Fermer",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.info, color: Colors.white),
      )
    );
  }

  final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    fixedSize: const Size(300, 75),
    textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    elevation: 5,
    backgroundColor: const Color.fromARGB(255, 66, 232, 107),
    shadowColor: Colors.black,
  );

  Widget _button1(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(450, 75),
        textStyle: const TextStyle(fontSize: 38, fontWeight: FontWeight.w600),
        backgroundColor: const Color.fromARGB(255, 66, 232, 107),
        elevation: 8,
        shadowColor: Colors.black38,
      ),
      icon: const Icon(Icons.folder_open, size: 32),
      label: const Text(" Select a folder"),
      onPressed: () async {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory != null) {
          setState(() {
            folderPath = selectedDirectory;
            oldPythonFiles = _getTestPythonFiles(selectedDirectory);
            pythonFiles.clear();
            filterApplied = false;
          });
        }
      },
    );
  }

  Widget _button2(BuildContext context) {
    return ElevatedButton.icon(
      style: _buttonStyle,
      icon: const Icon(Icons.rule),
      label: const Text("Import rules"),
      onPressed: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom, allowedExtensions: ['txt']);
        if (result != null && result.files.single.path != null) {
          setState(() {
            rulesPath = result.files.single.path!;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Rules imported!"),
                backgroundColor: Colors.green,
              ),
            );
          });
        }
      },
    );
  }

  Widget _button3(BuildContext context) {
    return ElevatedButton.icon(
      style: _buttonStyle.copyWith(
        backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 66, 232, 107)),
      ),
      icon: const Icon(Icons.filter_alt, size: 32),
      label: const Text("Filter"),
      onPressed: (folderPath == null)
          ? null
          : () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['txt'],
              );

              if (result != null && result.files.single.path != null) {
                String rulesFile = result.files.single.path!;

                final lastResult = await _runPythonScript(
                  'filtre.py',
                  [folderPath!, rulesFile],
                  context,
                );

                try {
                  if (lastResult != null && lastResult.exitCode == 0) {
                    final filteredFiles = jsonDecode(lastResult.stdout.toString()) as List<dynamic>;
                    setState(() {
                      pythonFiles = List<String>.from(filteredFiles);
                      filterApplied = true;
                      if (pythonFiles.isNotEmpty) {
                        folderPath = File(pythonFiles.first).parent.path;
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${filteredFiles.length} filtered files."),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (lastResult != null) {
                    print("Error script : ${lastResult.stderr}");
                  }
                } catch (e) {
                  print("Error decoding JSON: $e");
                }
              }
            },
    );
  }

  Widget _button4(BuildContext context) {
    return ElevatedButton.icon(
      style: _buttonStyle.copyWith(
        backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 66, 232, 107)),
      ),
      icon: const Icon(Icons.edit),
      label: const Text("Change rules"),
      onPressed: rulesPath == null
          ? null
          : () async {
              final file = File(rulesPath!);
              String content = await file.readAsString();

              final controller = TextEditingController(text: content);

              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color.fromARGB(255, 66, 232, 107),
                  title: const Text("Edit rules file", style: TextStyle(color: Colors.black)),
                  content: SizedBox(
                    width: 500,
                    height: 400,
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        fillColor: Color.fromARGB(255, 66, 232, 107),
                        filled: true,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text("Validate", style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        await file.writeAsString(controller.text);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅Saved rules file!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
    );
  }

  Widget _button5(BuildContext context) {
    return ElevatedButton.icon(
      style: _buttonStyle.copyWith(
        backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 66, 232, 107)),
      ),
      icon: const Icon(Icons.table_chart),
      label: const Text("Generate Excel"),
      onPressed: (folderPath == null || rulesPath == null || (filterApplied && pythonFiles.isEmpty))
          ? null
          : () async {
              String? selectedDir = await FilePicker.platform.getDirectoryPath();
              if (selectedDir == null) return;

              String? fileName = await showDialog<String>(
                context: context,
                builder: (context) {
                  String tempName = "results.xlsx";
                  return AlertDialog(
                    backgroundColor: const Color.fromARGB(255, 66, 232, 107),
                    title: const Text("Excel file name", style: TextStyle(color: Colors.white)),
                    content: TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Enter the file name",
                        hintStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      onSubmitted: (value) {
                        tempName = value;
                        Navigator.pop(context, tempName);
                      },
                      onChanged: (value) => tempName = value,
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text("Validate", style: TextStyle(color: Colors.white)),
                        onPressed: () => Navigator.pop(context, tempName),
                      ),
                    ],
                  );
                },
              );

              if (fileName == null || fileName.trim().isEmpty) return;

              String fullPath = path.join(selectedDir, fileName);
              if (!fullPath.toLowerCase().endsWith(".xlsx")) {
                fullPath += ".xlsx";
              }
              String effectiveFolder = folderPath!;
              if (pythonFiles.isNotEmpty) {
                final tempDir = await Directory.systemTemp.createTemp("filtered_py");
                for (final filePath in pythonFiles) {
                  final original = File(filePath);
                  final copyPath = path.join(tempDir.path, path.basename(filePath));
                  await original.copy(copyPath);
                }
                effectiveFolder = tempDir.path;
              }
              await _runPythonScript(
                "excel_generator.py",
                [effectiveFolder, fullPath, rulesPath ?? 'rules.txt'],
                context,
              );
            },
    );
  }

  Widget _button6(BuildContext context) {
    return ElevatedButton.icon(
      style: _buttonStyle.copyWith(
        backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 66, 232, 107)),
      ),
      icon: const Icon(Icons.warning),
      label: const Text("Black & Flake8"),
      onPressed: (folderPath == null || (filterApplied && pythonFiles.isEmpty))
          ? null
          : () async {
              String effectiveFolder = folderPath!;

              if (filterApplied && pythonFiles.isNotEmpty) {
                final tempDir = await Directory.systemTemp.createTemp("filtered_py");
                for (final filePath in pythonFiles) {
                  final original = File(filePath);
                  final copyPath = path.join(tempDir.path, path.basename(filePath));
                  await original.copy(copyPath);
                }
                effectiveFolder = tempDir.path;
              }

              await _runPythonScript("black_flake_warning.py", [effectiveFolder], context);
            },
    );
  }

  Widget _button7(BuildContext context) {
    return ElevatedButton.icon(
      style: _buttonStyle.copyWith(
        textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 66, 232, 107)),
      ),
      icon: const Icon(Icons.build),
      label: const Text("AutoBlack & AutoFlake"),
      onPressed: (folderPath == null || (filterApplied && pythonFiles.isEmpty))
          ? null
          : () async {
              String effectiveFolder = folderPath!;

              if (filterApplied && pythonFiles.isNotEmpty) {
                final tempDir = await Directory.systemTemp.createTemp("filtered_py");
                for (final filePath in pythonFiles) {
                  final original = File(filePath);
                  final copyPath = path.join(tempDir.path, path.basename(filePath));
                  await original.copy(copyPath);
                }
                effectiveFolder = tempDir.path;
              }

              await _runPythonScript("autofix.py", [effectiveFolder], context);
            },
    );
  }

  Widget _button8(BuildContext context) {
    return ElevatedButton.icon(
      style: _buttonStyle.copyWith(
        backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 66, 232, 107)),
      ),
      icon: const Icon(Icons.delete),
      label: const Text("Delete results"),
      onPressed: folderPath == null
          ? null
          : () => _runPythonScript("delete_results.py", [folderPath!], context),
    );
  }
}
