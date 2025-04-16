import 'package:flutter_test/flutter_test.dart';
import 'package:no_screen_recording/no_screen_recording.dart';
import 'package:no_screen_recording/no_screen_recording_platform_interface.dart';
import 'package:no_screen_recording/no_screen_recording_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNoScreenRecordingPlatform
    with MockPlatformInterfaceMixin
    implements NoScreenRecordingPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> disableScreenRecordingDetection() {
    // TODO: implement disableScreenRecordingDetection
    throw UnimplementedError();
  }

  @override
  Future<void> enableScreenRecordingDetection() {
    // TODO: implement enableScreenRecordingDetection
    throw UnimplementedError();
  }

  @override
  Future<bool> isScreenRecordingActive() {
    // TODO: implement isScreenRecordingActive
    throw UnimplementedError();
  }

  @override
  // TODO: implement onScreenRecordingStateChanged
  Stream<bool> get onScreenRecordingStateChanged => throw UnimplementedError();

  @override
  Future<void> setSecureMode(bool enable) {
    // TODO: implement setSecureMode
    throw UnimplementedError();
  }
}

void main() {
  final NoScreenRecordingPlatform initialPlatform =
      NoScreenRecordingPlatform.instance;

  test('$MethodChannelNoScreenRecording is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNoScreenRecording>());
  });
}
