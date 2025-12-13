package com.example.ai_mentor_coach

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.PowerManager
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import android.Manifest

/**
 * Foreground service for voice capture that works from the lock screen.
 *
 * Features:
 * - Persistent notification visible on lock screen
 * - Quick action button to start voice capture
 * - Wakes device for voice capture when screen is off
 * - Communicates results back to Flutter via method channel
 */
class VoiceCaptureService : Service() {
    companion object {
        private const val TAG = "VoiceCaptureService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "voice_capture_channel"
        private const val CHANNEL_NAME = "Voice Capture"

        const val ACTION_START_SERVICE = "com.mentorme.ACTION_START_SERVICE"
        const val ACTION_STOP_SERVICE = "com.mentorme.ACTION_STOP_SERVICE"
        const val ACTION_START_VOICE_CAPTURE = "com.mentorme.ACTION_START_VOICE_CAPTURE"
        const val ACTION_VOICE_RESULT = "com.mentorme.ACTION_VOICE_RESULT"

        const val EXTRA_TRANSCRIPT = "transcript"

        private const val FLUTTER_ENGINE_ID = "mentorme_engine"
        private const val LOCK_SCREEN_VOICE_CHANNEL = "com.mentorme/lock_screen_voice"
    }

    private var speechRecognizer: SpeechRecognizer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var isListening = false
    private var methodChannel: MethodChannel? = null

    // Broadcast receiver for notification actions
    private val actionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_START_VOICE_CAPTURE -> {
                    Log.d(TAG, "Voice capture action triggered from notification")
                    startVoiceCapture()
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")

        createNotificationChannel()

        // Register broadcast receiver for notification actions
        val filter = IntentFilter(ACTION_START_VOICE_CAPTURE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(actionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(actionReceiver, filter)
        }

        // Set up method channel to communicate with Flutter
        setupMethodChannel()
    }

    private fun setupMethodChannel() {
        // Try to get the cached Flutter engine
        val flutterEngine = FlutterEngineCache.getInstance().get(FLUTTER_ENGINE_ID)
        if (flutterEngine != null) {
            methodChannel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                LOCK_SCREEN_VOICE_CHANNEL
            )
            Log.d(TAG, "Method channel set up successfully")
        } else {
            Log.w(TAG, "Flutter engine not cached - will broadcast results instead")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service onStartCommand: ${intent?.action}")

        when (intent?.action) {
            ACTION_START_SERVICE -> {
                startForegroundWithNotification()
            }
            ACTION_STOP_SERVICE -> {
                stopSelf()
            }
            ACTION_START_VOICE_CAPTURE -> {
                startVoiceCapture()
            }
        }

        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Quick voice capture for todos"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }

    private fun startForegroundWithNotification() {
        val notification = buildNotification(isListening = false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        Log.d(TAG, "Foreground service started with notification")
    }

    private fun buildNotification(isListening: Boolean): Notification {
        // Intent to open the app
        val openAppIntent = packageManager
            .getLaunchIntentForPackage(packageName)
            ?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }

        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent for voice capture action
        val voiceCaptureIntent = Intent(ACTION_START_VOICE_CAPTURE).apply {
            setPackage(packageName)
        }

        val voiceCapturePendingIntent = PendingIntent.getBroadcast(
            this,
            1,
            voiceCaptureIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent to stop service
        val stopIntent = Intent(this, VoiceCaptureService::class.java).apply {
            action = ACTION_STOP_SERVICE
        }

        val stopPendingIntent = PendingIntent.getService(
            this,
            2,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentTitle(if (isListening) "Listening..." else "MentorMe Voice Capture")
            .setContentText(
                if (isListening) "Say what you need to do"
                else "Tap mic to add a todo by voice"
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(openAppPendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)

        if (!isListening) {
            // Add voice capture action when not listening
            builder.addAction(
                android.R.drawable.ic_btn_speak_now,
                "🎤 Add Todo",
                voiceCapturePendingIntent
            )
        }

        // Always add stop action
        builder.addAction(
            android.R.drawable.ic_menu_close_clear_cancel,
            "Disable",
            stopPendingIntent
        )

        return builder.build()
    }

    private fun updateNotification(isListening: Boolean) {
        val notification = buildNotification(isListening)
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager?.notify(NOTIFICATION_ID, notification)
    }

    private fun startVoiceCapture() {
        if (isListening) {
            Log.d(TAG, "Already listening, ignoring request")
            return
        }

        // Check permission
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "Microphone permission not granted")
            sendResultToFlutter(null, "Permission denied")
            return
        }

        // Check if speech recognition is available
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            Log.e(TAG, "Speech recognition not available")
            sendResultToFlutter(null, "Speech recognition not available")
            return
        }

        // Acquire wake lock to keep CPU running
        acquireWakeLock()

        isListening = true
        updateNotification(isListening = true)

        // Create speech recognizer
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    Log.d(TAG, "Ready for speech")
                }

                override fun onBeginningOfSpeech() {
                    Log.d(TAG, "Beginning of speech")
                }

                override fun onRmsChanged(rmsdB: Float) {}

                override fun onBufferReceived(buffer: ByteArray?) {}

                override fun onEndOfSpeech() {
                    Log.d(TAG, "End of speech")
                }

                override fun onError(error: Int) {
                    val errorMessage = when (error) {
                        SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                        SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                        SpeechRecognizer.ERROR_NETWORK -> "Network error"
                        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                        SpeechRecognizer.ERROR_NO_MATCH -> "No speech recognized"
                        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
                        SpeechRecognizer.ERROR_SERVER -> "Server error"
                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Speech timeout"
                        else -> "Unknown error: $error"
                    }
                    Log.e(TAG, "Speech recognition error: $errorMessage")

                    finishListening()

                    // Only send error for actual errors, not timeout/no match
                    if (error != SpeechRecognizer.ERROR_NO_MATCH &&
                        error != SpeechRecognizer.ERROR_SPEECH_TIMEOUT) {
                        sendResultToFlutter(null, errorMessage)
                    }
                }

                override fun onResults(results: Bundle?) {
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val transcript = matches?.firstOrNull()

                    Log.d(TAG, "Speech result: $transcript")

                    finishListening()

                    if (transcript != null) {
                        sendResultToFlutter(transcript, null)
                    }
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    Log.d(TAG, "Partial result: ${matches?.firstOrNull()}")
                }

                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
        }

        // Start listening
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 3000)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1500)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 1500)
        }

        Log.d(TAG, "Starting speech recognition")
        speechRecognizer?.startListening(intent)
    }

    private fun finishListening() {
        isListening = false
        updateNotification(isListening = false)
        releaseWakeLock()
        cleanupSpeechRecognizer()
    }

    private fun cleanupSpeechRecognizer() {
        try {
            speechRecognizer?.cancel()
            speechRecognizer?.destroy()
        } catch (e: Exception) {
            Log.w(TAG, "Error cleaning up speech recognizer: ${e.message}")
        }
        speechRecognizer = null
    }

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "MentorMe:VoiceCaptureWakeLock"
            )
        }
        wakeLock?.acquire(30000) // 30 second timeout
        Log.d(TAG, "Wake lock acquired")
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                Log.d(TAG, "Wake lock released")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error releasing wake lock: ${e.message}")
        }
    }

    private fun sendResultToFlutter(transcript: String?, error: String?) {
        // Try method channel first
        if (methodChannel != null) {
            try {
                methodChannel?.invokeMethod("onVoiceResult", mapOf(
                    "transcript" to transcript,
                    "error" to error
                ))
                Log.d(TAG, "Sent result via method channel")
                return
            } catch (e: Exception) {
                Log.w(TAG, "Failed to send via method channel: ${e.message}")
            }
        }

        // Fallback to broadcast
        val resultIntent = Intent(ACTION_VOICE_RESULT).apply {
            setPackage(packageName)
            putExtra(EXTRA_TRANSCRIPT, transcript)
            putExtra("error", error)
        }
        sendBroadcast(resultIntent)
        Log.d(TAG, "Sent result via broadcast")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")

        try {
            unregisterReceiver(actionReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Error unregistering receiver: ${e.message}")
        }

        cleanupSpeechRecognizer()
        releaseWakeLock()
    }
}
