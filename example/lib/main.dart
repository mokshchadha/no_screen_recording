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
      ),
      home: const NoScreenRecording(
        // The child is your normal app content
        child: HomePage(),
        // Custom blank screen (optional)
        blankScreen: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Text(
              'Screen recording not allowed',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('No Screen Recording Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'This is a sensitive content app',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Text(
              'Screenshots are allowed, but screen recording will show a blank screen',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            StreamBuilder<bool>(
              stream: NoScreenRecordingUtil.onScreenRecordingStateChanged,
              initialData: false,
              builder: (context, snapshot) {
                final isRecording = snapshot.data ?? false;
                return Text(
                  isRecording
                      ? 'Screen Recording Detected!'
                      : 'No Screen Recording Detected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isRecording ? Colors.red : Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
