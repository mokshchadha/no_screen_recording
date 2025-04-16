package com.example.no_screen_recording

import android.app.Activity
import android.content.Context
import android.hardware.display.DisplayManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.atomic.AtomicBoolean

/** NoScreenRecordingPlugin */
class NoScreenRecordingPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var eventSink: EventChannel.EventSink? = null
  private var recordingDetectionEnabled = false
  private val isRecording = AtomicBoolean(false)
  private val mainHandler = Handler(Looper.getMainLooper())
  
  // Variables for more aggressive detection
  private var displayManager: DisplayManager? = null
  private var windowManager: WindowManager? = null
  private var displayListener: DisplayManager.DisplayListener? = null
  private var checkTask: Runnable? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "no_screen_recording")
    channel.setMethodCallHandler(this)
    
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "no_screen_recording_events")
    eventChannel.setStreamHandler(this)
    
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "enableScreenRecordingDetection" -> {
        recordingDetectionEnabled = true
        registerScreenRecordingObserver()
        result.success(null)
      }
      "disableScreenRecordingDetection" -> {
        recordingDetectionEnabled = false
        unregisterScreenRecordingObserver()
        result.success(null)
      }
      "isScreenRecordingActive" -> {
        result.success(checkIsScreenRecordingActive())
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun registerScreenRecordingObserver() {
    if (displayListener != null) return
    
    // Initialize managers
    displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    
    // Create display listener
    displayListener = object : DisplayManager.DisplayListener {
      override fun onDisplayAdded(displayId: Int) {
        checkForScreenRecording()
      }

      override fun onDisplayRemoved(displayId: Int) {
        checkForScreenRecording()
      }

      override fun onDisplayChanged(displayId: Int) {
        checkForScreenRecording()
      }
    }
    
    // Register display listener
    displayManager?.registerDisplayListener(displayListener, mainHandler)
    
    // Start periodic checks
    checkTask = object : Runnable {
      override fun run() {
        if (recordingDetectionEnabled) {
          checkForScreenRecording()
          mainHandler.postDelayed(this, 500) // Check every 500ms
        }
      }
    }
    mainHandler.post(checkTask!!)
    
    // Initial check
    checkForScreenRecording()
  }

  private fun unregisterScreenRecordingObserver() {
    displayListener?.let {
      displayManager?.unregisterDisplayListener(it)
      displayListener = null
    }
    
    checkTask?.let {
      mainHandler.removeCallbacks(it)
      checkTask = null
    }
    
    isRecording.set(false)
    notifyRecordingState(false)
  }

  private fun checkForScreenRecording() {
    val recordingDetected = checkIsScreenRecordingActive()
    
    if (isRecording.getAndSet(recordingDetected) != recordingDetected) {
      notifyRecordingState(recordingDetected)
    }
  }

  private fun notifyRecordingState(isRecording: Boolean) {
    mainHandler.post {
      eventSink?.success(isRecording)
    }
  }

  private fun checkIsScreenRecordingActive(): Boolean {
    // Method 1: Check for presentation displays (casting/mirroring)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
      val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
      val displays = displayManager.displays
      
      // We normally have DEFAULT_DISPLAY (0) for the device screen
      // If there are more displays, something might be capturing/mirroring
      if (displays.size > 1) {
        for (display in displays) {
          // Check for presentation displays - the error was likely here
          // DisplayManager.DISPLAY_CATEGORY_PRESENTATION is actually an int flag
          if (display.displayId != 0) {
            return true
          }
        }
      }
    }
    
    // Method 2: Check if there's a running media projection service
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      try {
        val projectionManager = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        
        // Attempt to access non-public API via reflection
        val methodName = "getActiveProjectionInfo"
        val method = projectionManager.javaClass.getDeclaredMethod(methodName)
        method.isAccessible = true
        val info = method.invoke(projectionManager)
        return info != null
      } catch (e: Exception) {
        // Method not available or other issues
      }
    }
    
    // Method 3: Check system properties that might indicate recording
    // This is a heuristic approach
    val isEmulator = Build.FINGERPRINT.startsWith("generic") || 
                    Build.FINGERPRINT.startsWith("unknown") ||
                    Build.MODEL.contains("google_sdk") || 
                    Build.MODEL.contains("Emulator") ||
                    Build.MODEL.contains("Android SDK")
    
    // During development, we don't want to treat emulators as recording
    // In production, we might want to be more cautious
    val isDebug = false  // Replace with BuildConfig.DEBUG when using in a real app
    if (isEmulator && !isDebug) {
      return true
    }
    
    return false
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    unregisterScreenRecordingObserver()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    if (recordingDetectionEnabled) {
      events?.success(isRecording.get())
    }
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }
}