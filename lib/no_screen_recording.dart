import 'package:flutter/material.dart';
import 'no_screen_recording_platform_interface.dart';

/// A widget that wraps your app content and prevents screen recording
/// by showing a blank screen when screen recording is detected.
class NoScreenRecording extends StatefulWidget {
  /// The child widget to display when screen recording is not active.
  final Widget child;

  /// The widget to display when screen recording is detected.
  /// By default, this is a blank white screen.
  final Widget blankScreen;

  /// Creates a new [NoScreenRecording] widget.
  const NoScreenRecording({
    Key? key,
    required this.child,
    this.blankScreen = const ColoredBox(color: Colors.white),
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
}
