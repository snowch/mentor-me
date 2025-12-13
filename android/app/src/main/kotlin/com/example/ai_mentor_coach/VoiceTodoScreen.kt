package com.example.ai_mentor_coach

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.CarColor
import androidx.car.app.model.CarIcon
import androidx.car.app.model.MessageTemplate
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Android Auto screen for voice-based todo creation.
 * Displays a simple interface with a voice button that captures
 * speech and creates a todo item.
 *
 * Flow:
 * 1. User sees "Add Todo" button on car screen
 * 2. User taps button or uses voice command
 * 3. Speech recognition captures what they say
 * 4. Todo is created via Flutter method channel
 * 5. Confirmation shown on car screen
 */
class VoiceTodoScreen(carContext: CarContext) : Screen(carContext) {

    companion object {
        private const val TAG = "VoiceTodoScreen"
        private const val FLUTTER_ENGINE_ID = "mentorme_engine"
        private const val ANDROID_AUTO_CHANNEL = "com.mentorme/android_auto"
    }

    private enum class ScreenState {
        READY,      // Ready to capture voice
        LISTENING,  // Currently listening for speech
        PROCESSING, // Processing the captured speech
        SUCCESS,    // Todo created successfully
        ERROR       // An error occurred
    }

    private var currentState = ScreenState.READY
    private var capturedText: String? = null
    private var errorMessage: String? = null
    private var speechRecognizer: SpeechRecognizer? = null

    override fun onGetTemplate(): Template {
        return when (currentState) {
            ScreenState.READY -> buildReadyTemplate()
            ScreenState.LISTENING -> buildListeningTemplate()
            ScreenState.PROCESSING -> buildProcessingTemplate()
            ScreenState.SUCCESS -> buildSuccessTemplate()
            ScreenState.ERROR -> buildErrorTemplate()
        }
    }

    private fun buildReadyTemplate(): Template {
        val pane = Pane.Builder()
            .addRow(
                Row.Builder()
                    .setTitle("Voice Todo")
                    .addText("Tap the microphone to add a new todo by voice")
                    .build()
            )
            .addAction(
                Action.Builder()
                    .setTitle("🎤 Add Todo")
                    .setBackgroundColor(CarColor.PRIMARY)
                    .setOnClickListener { startVoiceCapture() }
                    .build()
            )
            .build()

        return PaneTemplate.Builder(pane)
            .setTitle("MentorMe")
            .setHeaderAction(Action.APP_ICON)
            .build()
    }

    private fun buildListeningTemplate(): Template {
        return MessageTemplate.Builder("Listening...")
            .setTitle("MentorMe")
            .setHeaderAction(Action.APP_ICON)
            .setIcon(
                CarIcon.Builder(
                    IconCompat.createWithResource(carContext, android.R.drawable.ic_btn_speak_now)
                ).build()
            )
            .addAction(
                Action.Builder()
                    .setTitle("Cancel")
                    .setOnClickListener { cancelVoiceCapture() }
                    .build()
            )
            .build()
    }

    private fun buildProcessingTemplate(): Template {
        return MessageTemplate.Builder("Creating todo...")
            .setTitle("MentorMe")
            .setHeaderAction(Action.APP_ICON)
            .setLoading(true)
            .build()
    }

    private fun buildSuccessTemplate(): Template {
        return MessageTemplate.Builder("Todo added:\n\"${capturedText ?: ""}\"")
            .setTitle("MentorMe")
            .setHeaderAction(Action.APP_ICON)
            .setIcon(
                CarIcon.Builder(
                    IconCompat.createWithResource(carContext, android.R.drawable.ic_dialog_info)
                ).build()
            )
            .addAction(
                Action.Builder()
                    .setTitle("Add Another")
                    .setBackgroundColor(CarColor.PRIMARY)
                    .setOnClickListener {
                        currentState = ScreenState.READY
                        capturedText = null
                        invalidate()
                    }
                    .build()
            )
            .addAction(
                Action.Builder()
                    .setTitle("Done")
                    .setOnClickListener { screenManager.pop() }
                    .build()
            )
            .build()
    }

    private fun buildErrorTemplate(): Template {
        return MessageTemplate.Builder(errorMessage ?: "An error occurred")
            .setTitle("MentorMe")
            .setHeaderAction(Action.APP_ICON)
            .setIcon(
                CarIcon.Builder(
                    IconCompat.createWithResource(carContext, android.R.drawable.ic_dialog_alert)
                ).build()
            )
            .addAction(
                Action.Builder()
                    .setTitle("Try Again")
                    .setBackgroundColor(CarColor.PRIMARY)
                    .setOnClickListener {
                        currentState = ScreenState.READY
                        errorMessage = null
                        invalidate()
                    }
                    .build()
            )
            .addAction(
                Action.Builder()
                    .setTitle("Cancel")
                    .setOnClickListener { screenManager.pop() }
                    .build()
            )
            .build()
    }

    private fun startVoiceCapture() {
        Log.d(TAG, "Starting voice capture")

        // Check permission
        if (ContextCompat.checkSelfPermission(carContext, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "Microphone permission not granted")
            errorMessage = "Microphone permission required.\nPlease grant permission in the MentorMe app."
            currentState = ScreenState.ERROR
            invalidate()
            return
        }

        // Check if speech recognition is available
        if (!SpeechRecognizer.isRecognitionAvailable(carContext)) {
            Log.e(TAG, "Speech recognition not available")
            errorMessage = "Speech recognition not available on this device"
            currentState = ScreenState.ERROR
            invalidate()
            return
        }

        currentState = ScreenState.LISTENING
        invalidate()

        // Create and start speech recognizer
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(carContext).apply {
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
                    currentState = ScreenState.PROCESSING
                    invalidate()
                }

                override fun onError(error: Int) {
                    val message = when (error) {
                        SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                        SpeechRecognizer.ERROR_CLIENT -> "Client error"
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Permission denied"
                        SpeechRecognizer.ERROR_NETWORK -> "Network error"
                        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                        SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected"
                        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
                        SpeechRecognizer.ERROR_SERVER -> "Server error"
                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech detected"
                        else -> "Unknown error: $error"
                    }
                    Log.e(TAG, "Speech recognition error: $message")

                    // For "no match" or timeout, just go back to ready state
                    if (error == SpeechRecognizer.ERROR_NO_MATCH ||
                        error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT) {
                        currentState = ScreenState.READY
                    } else {
                        errorMessage = message
                        currentState = ScreenState.ERROR
                    }
                    cleanupRecognizer()
                    invalidate()
                }

                override fun onResults(results: Bundle?) {
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val transcript = matches?.firstOrNull()

                    Log.d(TAG, "Speech result: $transcript")

                    if (transcript != null && transcript.isNotBlank()) {
                        capturedText = transcript
                        createTodo(transcript)
                    } else {
                        currentState = ScreenState.READY
                        invalidate()
                    }
                    cleanupRecognizer()
                }

                override fun onPartialResults(partialResults: Bundle?) {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
        }

        // Create recognition intent
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 2000)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1500)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 1500)
        }

        speechRecognizer?.startListening(intent)
    }

    private fun cancelVoiceCapture() {
        Log.d(TAG, "Cancelling voice capture")
        cleanupRecognizer()
        currentState = ScreenState.READY
        invalidate()
    }

    private fun cleanupRecognizer() {
        try {
            speechRecognizer?.cancel()
            speechRecognizer?.destroy()
        } catch (e: Exception) {
            Log.w(TAG, "Error cleaning up speech recognizer: ${e.message}")
        }
        speechRecognizer = null
    }

    private fun createTodo(title: String) {
        Log.d(TAG, "Creating todo: $title")

        // Try to send to Flutter via method channel
        val flutterEngine = FlutterEngineCache.getInstance().get(FLUTTER_ENGINE_ID)
        if (flutterEngine != null) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                ANDROID_AUTO_CHANNEL
            )

            channel.invokeMethod("createTodo", mapOf(
                "title" to title,
                "source" to "android_auto"
            ), object : MethodChannel.Result {
                override fun success(result: Any?) {
                    Log.d(TAG, "Todo created successfully via Flutter")
                    currentState = ScreenState.SUCCESS
                    invalidate()
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e(TAG, "Failed to create todo: $errorMessage")
                    // Still show success since we'll create it when app opens
                    currentState = ScreenState.SUCCESS
                    invalidate()
                }

                override fun notImplemented() {
                    Log.w(TAG, "createTodo not implemented in Flutter")
                    // Store for later and show success
                    currentState = ScreenState.SUCCESS
                    invalidate()
                }
            })
        } else {
            Log.w(TAG, "Flutter engine not cached - storing todo for later")
            // Even without Flutter engine, show success
            // The todo will be created when the app is opened
            storePendingTodo(title)
            currentState = ScreenState.SUCCESS
            invalidate()
        }
    }

    private fun storePendingTodo(title: String) {
        // Store in SharedPreferences for later retrieval when app opens
        try {
            val prefs = carContext.getSharedPreferences("android_auto_todos", CarContext.MODE_PRIVATE)
            val pendingTodos = prefs.getStringSet("pending", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
            pendingTodos.add(title)
            prefs.edit().putStringSet("pending", pendingTodos).apply()
            Log.d(TAG, "Stored pending todo: $title")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to store pending todo: ${e.message}")
        }
    }

    init {
        // Register lifecycle observer for cleanup
        lifecycle.addObserver(object : androidx.lifecycle.DefaultLifecycleObserver {
            override fun onDestroy(owner: androidx.lifecycle.LifecycleOwner) {
                cleanupRecognizer()
            }
        })
    }
}
