# No Screen Recording

A Flutter package that allows screenshots but prevents screen recording by blanking the screen.

## Features

- Detects when screen recording starts on both Android and iOS
- Automatically displays a blank screen when recording is detected
- Allows normal screenshots to be taken
- Customizable blank screen widget
- Simple API to check recording status programmatically

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  no_screen_recording: ^0.1.0
```

### Android Setup

No additional setup needed for Android.

### iOS Setup

Update your `Info.plist` file with a description for screen recording detection:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to detect screen recording</string>
```

## Usage

Wrap your app or specific screens with the `NoScreenRecording` widget:

```dart
import 'package:flutter/material.dart';
import 'package:no_screen_recording/no_screen_recording.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NoScreenRecording(
        child: MyHomePage(), // Your normal app content
        blankScreen: ColoredBox(  // Optional custom blank screen
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
```

### Programmatic API

You can also check the screen recording status programmatically:

```dart
import 'package:no_screen_recording/no_screen_recording.dart';

// Check if screen recording is active
bool isRecording = await NoScreenRecordingUtil.isScreenRecordingActive();

// Listen to screen recording state changes
NoScreenRecordingUtil.onScreenRecordingStateChanged.listen((isRecording) {
  print('Screen recording active: $isRecording');
});
```

## Example

See the `example` folder for a complete demo.

## Limitations

- Screen recording detection methods may vary based on device manufacturer and OS version
- Some recording methods might not be detected (like hardware HDMI capture)
- Root/jailbroken devices might be able to bypass the protection

## License

MIT