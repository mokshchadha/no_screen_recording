import Flutter
import UIKit

public class NoScreenRecordingPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var screenCaptureDetectionEnabled = false
    private var timer: Timer?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "no_screen_recording", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "no_screen_recording_events", binaryMessenger: registrar.messenger())
        
        let instance = NoScreenRecordingPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enableScreenRecordingDetection":
            screenCaptureDetectionEnabled = true
            startMonitoring()
            result(nil)
        case "disableScreenRecordingDetection":
            screenCaptureDetectionEnabled = false
            stopMonitoring()
            result(nil)
        case "isScreenRecordingActive":
            result(isScreenRecordingActive())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startMonitoring() {
        stopMonitoring()
        
        // Add screen recording notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureStatusChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        // Start timer as a backup method to check recording status
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.screenCaptureDetectionEnabled else { return }
            self.checkAndReportScreenRecordingStatus()
        }
        
        // Initial status check
        checkAndReportScreenRecordingStatus()
    }
    
    private func stopMonitoring() {
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func screenCaptureStatusChanged(_ notification: Notification) {
        checkAndReportScreenRecordingStatus()
    }
    
    private func checkAndReportScreenRecordingStatus() {
        let isRecording = isScreenRecordingActive()
        eventSink?(isRecording)
    }
    
    private func isScreenRecordingActive() -> Bool {
        // Check if screen is being captured (iOS 11+)
        if #available(iOS 11.0, *) {
            for screen in UIScreen.screens {
                if screen.isCaptured {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        if screenCaptureDetectionEnabled {
            events(isScreenRecordingActive())
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    deinit {
        stopMonitoring()
    }
}