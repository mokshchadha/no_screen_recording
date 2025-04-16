import Flutter
import UIKit
import AVFoundation

public class NoScreenRecordingPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var screenCaptureDetectionEnabled = false
    private var timer: Timer?
    private var secureTextEnabled = true
    private var blankOverlayWindow: UIWindow?
    private var previousOrientation: UIInterfaceOrientation = .portrait
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "no_screen_recording", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "no_screen_recording_events", binaryMessenger: registrar.messenger())
        
        let instance = NoScreenRecordingPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        
        // Register for orientation changes to update our overlay window if needed
        NotificationCenter.default.addObserver(instance, 
                                               selector: #selector(instance.orientationChanged),
                                               name: UIDevice.orientationDidChangeNotification, 
                                               object: nil)
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
        case "setSecureMode":
            if let args = call.arguments as? [String: Any],
               let enable = args["enable"] as? Bool {
                secureTextEnabled = enable
                if !enable {
                    removeBlankOverlay()
                } else if isScreenRecordingActive() {
                    showBlankOverlay()
                }
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startMonitoring() {
        stopMonitoring()
        
        // Add screen recording notification observer (iOS 11+)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureStatusChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        // Add airplay notification observer (may indicate screen mirroring)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureStatusChanged),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        
        // Start timer as a backup method to check recording status
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.screenCaptureDetectionEnabled else { return }
            self.checkAndReportScreenRecordingStatus()
        }
        
        // Initial status check
        checkAndReportScreenRecordingStatus()
    }
    
    private func stopMonitoring() {
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIScreen.didConnectNotification, object: nil)
        
        timer?.invalidate()
        timer = nil
        
        removeBlankOverlay()
    }
    
    @objc private func screenCaptureStatusChanged(_ notification: Notification) {
        checkAndReportScreenRecordingStatus()
    }
    
    @objc private func orientationChanged(_ notification: Notification) {
        // Update overlay window if it exists and recording is active
        if blankOverlayWindow != nil && isScreenRecordingActive() {
            removeBlankOverlay()
            showBlankOverlay()
        }
    }
    
    private func checkAndReportScreenRecordingStatus() {
        let isRecording = isScreenRecordingActive()
        
        // Handle overlay display based on recording status
        if isRecording && secureTextEnabled {
            showBlankOverlay()
        } else {
            removeBlankOverlay()
        }
        
        eventSink?(isRecording)
    }
    
    private func isScreenRecordingActive() -> Bool {
        var isRecording = false
        
        // Method 1: Check UIScreen.main.isCaptured (iOS 11+)
        if #available(iOS 11.0, *) {
            for screen in UIScreen.screens {
                if screen.isCaptured {
                    isRecording = true
                    break
                }
            }
        }
        
        // Method 2: Check for AirPlay mirroring
        if !isRecording && UIScreen.screens.count > 1 {
            isRecording = true
        }
        
        return isRecording
    }
    
    private func showBlankOverlay() {
        // Don't create multiple overlays
        guard blankOverlayWindow == nil else { return }
        
        DispatchQueue.main.async {
            // Create a new window at the highest window level
            let window = UIWindow(frame: UIScreen.main.bounds)
            
            // Set up the overlay view
            let overlayVC = UIViewController()
            overlayVC.view.backgroundColor = .white
            
            // Add a label with a message
            let label = UILabel()
            label.text = "Screen Recording Detected"
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            
            overlayVC.view.addSubview(label)
            
            // Center the label
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: overlayVC.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: overlayVC.view.centerYAnchor)
            ])
            
            window.rootViewController = overlayVC
            window.windowLevel = UIWindow.Level.alert + 1  // Above alert level
            window.makeKeyAndVisible()
            
            self.blankOverlayWindow = window
            
            // Store current orientation
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self.previousOrientation = windowScene.interfaceOrientation
            }
        }
    }
    
    private func removeBlankOverlay() {
        guard let window = blankOverlayWindow else { return }
        
        DispatchQueue.main.async {
            window.isHidden = true
            self.blankOverlayWindow = nil
        }
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
        NotificationCenter.default.removeObserver(self)
    }
}