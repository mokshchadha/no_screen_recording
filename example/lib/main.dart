import 'package:flutter/material.dart';
import 'package:no_screen_recording/no_screen_recording.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Screen Recording Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Wrap entire app with NoScreenRecording
      home: const NoScreenRecording(
        child: HomePage(),
        // Custom blank screen is optional
        blankScreen: CustomBlankScreen(),
        // Enable secure mode by default
        secureMode: true,
        // Optional callback for recording state changes
        onRecordingStateChanged: _handleRecordingStateChanged,
      ),
    );
  }

  static void _handleRecordingStateChanged(bool isRecording) {
    debugPrint('Screen recording state changed: $isRecording');
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _secureMode = true;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _checkRecordingStatus();

    // Listen for recording state changes
    NoScreenRecordingUtil.onScreenRecordingStateChanged.listen((isRecording) {
      if (mounted) {
        setState(() {
          _isRecording = isRecording;
        });
      }
    });
  }

  Future<void> _checkRecordingStatus() async {
    final isRecording = await NoScreenRecordingUtil.isScreenRecordingActive();
    if (mounted) {
      setState(() {
        _isRecording = isRecording;
      });
    }
  }

  void _toggleSecureMode(bool value) {
    setState(() {
      _secureMode = value;
    });
    NoScreenRecordingUtil.setSecureMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('No Screen Recording Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status card
              Card(
                elevation: 4,
                color: _isRecording ? Colors.red.shade50 : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _isRecording ? Icons.videocam : Icons.videocam_off,
                        color: _isRecording ? Colors.red : Colors.green,
                        size: 36,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRecording
                                  ? 'Screen Recording Detected!'
                                  : 'No Screen Recording Detected',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isRecording
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isRecording
                                  ? 'Content will be hidden while recording'
                                  : 'App content is visible',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Settings
              const Text(
                'Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Secure mode toggle
              SwitchListTile(
                title: const Text('Secure Mode'),
                subtitle: const Text('Enables additional protection features'),
                value: _secureMode,
                onChanged: _toggleSecureMode,
              ),

              const Divider(),

              // Sensitive content example
              const SizedBox(height: 16),
              const Text(
                'Sensitive Content Example',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Sample sensitive content
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Credit Card Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text('Card Number: **** **** **** 1234'),
                      const Text('Expiry Date: 12/25'),
                      const Text('CVV: ***'),
                      const SizedBox(height: 16),
                      Text(
                        'This information is protected from screen recording',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom blank screen to show when recording is detected
class CustomBlankScreen extends StatelessWidget {
  const CustomBlankScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 72,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'Recording Detected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Content is protected for security reasons',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
