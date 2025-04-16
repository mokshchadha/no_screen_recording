import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import './no_screen_recording_method_channel.dart';

abstract class NoScreenRecordingPlatform extends PlatformInterface {
  /// Constructs a NoScreenRecordingPlatform.
  NoScreenRecordingPlatform() : super(token: _token);

  static final Object _token = Object();

  static NoScreenRecordingPlatform _instance = MethodChannelNoScreenRecording();

  /// The default instance of [NoScreenRecordingPlatform] to use.
  static NoScreenRecordingPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NoScreenRecordingPlatform] when
  /// they register themselves.
  static set instance(NoScreenRecordingPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Enables the screen recording detection feature.
  Future<void> enableScreenRecordingDetection() {
    throw UnimplementedError(
        'enableScreenRecordingDetection() has not been implemented.');
  }

  /// Disables the screen recording detection feature.
  Future<void> disableScreenRecordingDetection() {
    throw UnimplementedError(
        'disableScreenRecordingDetection() has not been implemented.');
  }

  /// Checks if screen recording is currently active.
  Future<bool> isScreenRecordingActive() {
    throw UnimplementedError(
        'isScreenRecordingActive() has not been implemented.');
  }

  /// Listen to screen recording state changes.
  Stream<bool> get onScreenRecordingStateChanged {
    throw UnimplementedError(
        'onScreenRecordingStateChanged has not been implemented.');
  }

  /// Sets secure mode features (like FLAG_SECURE on Android)
  Future<void> setSecureMode(bool enable) {
    throw UnimplementedError('setSecureMode() has not been implemented.');
  }
}
