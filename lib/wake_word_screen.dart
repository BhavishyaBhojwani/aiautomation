import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';

class WakeWordScreen extends StatefulWidget {
  @override
  _WakeWordScreenState createState() => _WakeWordScreenState();
}

class _WakeWordScreenState extends State<WakeWordScreen> {
  PorcupineManager? _porcupineManager;

  final String accessKey =
      "7laEJEOP/kGxDnDs4eBaAQuIwTu0fVCZRFfVNtbB157BEibEjr3fXA==";

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'wake_word_channel',
        channelName: 'Wake Word Detection',
        channelDescription: 'Detects wake words in the background',
        priority: NotificationPriority.MAX,
        enableVibration: false,
      ),
      iosNotificationOptions: IOSNotificationOptions(
        showNotification: true,
        playSound: true,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _startForegroundTask();
  }

  Future<void> _startForegroundTask() async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'Wake Word Detection Active',
      notificationText: 'Listening for wake words in the background...',
    );

    // Initialize Porcupine with custom .ppn file
    try {
      // Load the asset path of your .ppn file
      String keywordAssetPath =
          await _loadAssetPath("assets/porcupine/heyjolly.ppn");
      print("Loaded keyword file path: $keywordAssetPath");

      // Initialize Porcupine with the custom keyword
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        accessKey,
        [keywordAssetPath],
        _wakeWordCallback,
      );

      // Start listening for wake words
      await _porcupineManager?.start();
    } catch (e) {
      print("Failed to initialize Porcupine: $e");
    }
  }

  // Helper function to load the asset path
  Future<String> _loadAssetPath(String assetPath) async {
    // Load the .ppn file from the assets folder
    final ByteData data = await rootBundle.load(assetPath);

    // Get the temporary directory using path_provider
    final Directory tempDir = await getTemporaryDirectory();
    final String tempPath = '${tempDir.path}/heyjolly.ppn';

    // Write the file to the temporary directory
    final File file =
        await File(tempPath).writeAsBytes(data.buffer.asUint8List());
    return file.path;
  }

  void _wakeWordCallback(int keywordIndex) {
    // Perform an action when the wake word is detected
    print("Wake word detected! Keyword index: $keywordIndex");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Wake word detected!")),
    );
  }

  @override
  void dispose() {
    _porcupineManager?.stop();
    _porcupineManager?.delete();
    FlutterForegroundTask.stopService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Wake Word Detection"),
      ),
      body: Center(
        child: Text("Listening for wake word..."),
      ),
    );
  }
}
