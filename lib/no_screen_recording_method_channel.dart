import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'no_screen_recording_platform_interface.dart';

/// An implementation of [NoScreenRecordingPlatform] that uses method channels.
class MethodChannelNoScreenRecording extends NoScreenRecordingPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('no_screen_recording');

  /// The event channel for screen recording state changes.
  @visibleForTesting
  final eventChannel = const EventChannel('no_screen_recording_events');

  @override
  Future<void> enableScreenRecordingDetection() async {
    await methodChannel.invokeMethod<void>('enableScreenRecordingDetection');
  }

  @override
  Future<void> disableScreenRecordingDetection() async {
    await methodChannel.invokeMethod<void>('disableScreenRecordingDetection');
  }

  @override
  Future<bool> isScreenRecordingActive() async {
    final bool? isActive =
        await methodChannel.invokeMethod<bool>('isScreenRecordingActive');
    return isActive ?? false;
  }

  @override
  Stream<bool> get onScreenRecordingStateChanged {
    return eventChannel.receiveBroadcastStream().map((event) => event as bool);
  }
}
