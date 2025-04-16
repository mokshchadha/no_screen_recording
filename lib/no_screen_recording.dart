import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'no_screen_recording_platform_interface.dart';

/// A widget that wraps your app content and prevents screen recording
/// by showing a blank screen when screen recording is detected.
class NoScreenRecording extends StatefulWidget {
  /// The child widget to display when screen recording is not active.
  final Widget child;

  /// The widget to display when screen recording is detected.
  /// By default, this is a blank white screen with a message.
  final Widget blankScreen;

  /// Whether to enable additional security features like FLAG_SECURE on Android
  final bool secureMode;

  /// Callback triggered when screen recording state changes
  final Function(bool isRecording)? onRecordingStateChanged;

  /// Creates a new [NoScreenRecording] widget.
  const NoScreenRecording({
    Key? key,
    required this.child,
    this.blankScreen = const _DefaultBlankScreen(),
    this.secureMode = true,
    this.onRecordingStateChanged,
  }) : super(key: key);

  @override
  State<NoScreenRecording> createState() => _NoScreenRecordingState();
}

class _NoScreenRecordingState extends State<NoScreenRecording>
    with WidgetsBindingObserver {
  bool _isRecording = false;
  late final Stream<bool> _recordingStateStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlatformState();
    _recordingStateStream =
        NoScreenRecordingPlatform.instance.onScreenRecordingStateChanged;
    _recordingStateStream.listen(_onRecordingStateChanged);
  }

  Future<void> _initPlatformState() async {
    try {
      await NoScreenRecordingPlatform.instance.enableScreenRecordingDetection();

      // Apply secure mode setting
      await NoScreenRecordingPlatform.instance.setSecureMode(widget.secureMode);

      _isRecording =
          await NoScreenRecordingPlatform.instance.isScreenRecordingActive();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to initialize no_screen_recording: $e');
    }
  }

  void _onRecordingStateChanged(bool isRecording) {
    if (mounted && _isRecording != isRecording) {
      setState(() {
        _isRecording = isRecording;
      });

      // Notify through callback if provided
      widget.onRecordingStateChanged?.call(isRecording);
    }
  }

  @override
  void didUpdateWidget(NoScreenRecording oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update secure mode if it changed
    if (oldWidget.secureMode != widget.secureMode) {
      NoScreenRecordingPlatform.instance.setSecureMode(widget.secureMode);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NoScreenRecordingPlatform.instance
          .isScreenRecordingActive()
          .then((value) {
        if (mounted && _isRecording != value) {
          setState(() {
            _isRecording = value;
          });

          // Notify through callback if provided
          widget.onRecordingStateChanged?.call(value);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NoScreenRecordingPlatform.instance.disableScreenRecordingDetection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isRecording ? widget.blankScreen : widget.child,
    );
  }
}

/// Default blank screen shown when recording is detected
class _DefaultBlankScreen extends StatelessWidget {
  const _DefaultBlankScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Screen Recording Detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Content is hidden for security reasons',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to directly access the platform functionality
class NoScreenRecordingUtil {
  /// Checks if screen recording is currently active.
  static Future<bool> isScreenRecordingActive() {
    return NoScreenRecordingPlatform.instance.isScreenRecordingActive();
  }

  /// Listen to screen recording state changes.
  static Stream<bool> get onScreenRecordingStateChanged {
    return NoScreenRecordingPlatform.instance.onScreenRecordingStateChanged;
  }

  /// Enables screen recording detection.
  static Future<void> enableScreenRecordingDetection() {
    return NoScreenRecordingPlatform.instance.enableScreenRecordingDetection();
  }

  /// Disables screen recording detection.
  static Future<void> disableScreenRecordingDetection() {
    return NoScreenRecordingPlatform.instance.disableScreenRecordingDetection();
  }

  /// Enables or disables secure mode features.
  static Future<void> setSecureMode(bool enable) {
    return NoScreenRecordingPlatform.instance.setSecureMode(enable);
  }
}
