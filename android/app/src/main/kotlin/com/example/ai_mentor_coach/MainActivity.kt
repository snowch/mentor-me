package com.example.ai_mentor_coach

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.Message
import com.google.ai.edge.litertlm.SamplerConfig
import java.io.File
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import android.Manifest
import android.content.Context
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MentorMe"
        private const val REQUEST_CODE_OPEN_DOCUMENT_TREE = 42
        private const val FLUTTER_ENGINE_ID = "mentorme_engine"
    }

    private val CHANNEL = "com.mentorme/on_device_ai"
    private val LOCAL_AI_CHANNEL = "com.mentorme/local_ai"
    private val SAF_CHANNEL = "com.mentorme/saf"
    private val VOICE_CAPTURE_CHANNEL = "com.mentorme/voice_capture"
    private val LOCK_SCREEN_VOICE_CHANNEL = "com.mentorme/lock_screen_voice"
    private val APP_ACTIONS_CHANNEL = "com.mentorme/app_actions"
    private val AICORE_PACKAGE = "com.google.android.aicore"
    private val PERMISSION_REQUEST_RECORD_AUDIO = 100

    // Pending App Action data to send to Flutter once engine is ready
    private var pendingAppAction: Map<String, Any?>? = null
    private var appActionsChannel: MethodChannel? = null

    // LiteRT LLM Engine instance with thread-safe access
    // Note: We create a fresh Conversation for each inference to avoid context accumulation
    private var engine: Engine? = null
    private val modelLock = Any()  // Lock for thread-safe model access

    // SAF callback result handler
    private var safResultHandler: MethodChannel.Result? = null

    // Voice capture
    private var speechRecognizer: SpeechRecognizer? = null
    private var voiceCaptureResultHandler: MethodChannel.Result? = null
    private var pendingPermissionResultHandler: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailability" -> {
                    try {
                        val availability = checkOnDeviceAIAvailability()
                        result.success(availability)
                    } catch (e: Exception) {
                        result.error("CHECK_FAILED", "Failed to check availability: ${e.message}", null)
                    }
                }
                "testInference" -> {
                    // TODO: Implement actual inference test when AICore SDK is integrated
                    result.success("Test inference not yet implemented")
                }
                "requestInstallation" -> {
                    // TODO: Implement AICore installation request
                    result.success(false)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Local AI inference channel (LiteRT LLM)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCAL_AI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath != null) {
                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                val success = loadLiteRTModel(modelPath)
                                result.success(success)
                            } catch (e: OutOfMemoryError) {
                                Log.e(TAG, "OUT OF MEMORY loading model: ${e.message}", e)
                                result.error("OUT_OF_MEMORY", "Out of memory - device cannot load this model", e.message)
                            } catch (e: Throwable) {
                                Log.e(TAG, "Load model error: ${e.message}", e)
                                result.error("LOAD_FAILED", "Failed to load model: ${e.message}", e.javaClass.simpleName)
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Model path is required", null)
                    }
                }
                "validateModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath != null) {
                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                val info = validateLiteRTModel(modelPath)
                                result.success(info)
                            } catch (e: OutOfMemoryError) {
                                Log.e(TAG, "OUT OF MEMORY validating model: ${e.message}", e)
                                result.error("OUT_OF_MEMORY", "Out of memory - device cannot load this model", e.message)
                            } catch (e: Throwable) {
                                Log.e(TAG, "Validate model error: ${e.message}", e)
                                result.error("VALIDATION_FAILED", "Failed to validate model: ${e.message}", e.javaClass.simpleName)
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Model path is required", null)
                    }
                }
                "inference" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt != null) {
                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                val response = runInference(prompt)
                                result.success(response)
                            } catch (e: OutOfMemoryError) {
                                Log.e(TAG, "OUT OF MEMORY during inference: ${e.message}", e)
                                result.error("OUT_OF_MEMORY", "Out of memory during inference", e.message)
                            } catch (e: Throwable) {
                                Log.e(TAG, "Inference error: ${e.message}", e)
                                result.error("INFERENCE_FAILED", "Inference failed: ${e.message}", e.javaClass.simpleName)
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Prompt is required", null)
                    }
                }
                "unloadModel" -> {
                    try {
                        unloadLiteRTModel()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Unload model error: ${e.message}", e)
                        result.error("UNLOAD_FAILED", "Failed to unload model: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Storage Access Framework channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SAF_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestFolderAccess" -> {
                    requestFolderAccess(result)
                }
                "listFiles" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val files = listSAFFiles(uriString)
                            result.success(files)
                        } catch (e: Exception) {
                            result.error("LIST_FAILED", "Failed to list files: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI is required", null)
                    }
                }
                "writeFile" -> {
                    val uriString = call.argument<String>("uri")
                    val fileName = call.argument<String>("fileName")
                    val content = call.argument<String>("content")
                    if (uriString != null && fileName != null && content != null) {
                        try {
                            val fileUri = writeSAFFile(uriString, fileName, content)
                            result.success(fileUri)
                        } catch (e: Exception) {
                            result.error("WRITE_FAILED", "Failed to write file: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI, fileName, and content are required", null)
                    }
                }
                "writeBytes" -> {
                    val uriString = call.argument<String>("uri")
                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    if (uriString != null && fileName != null && bytes != null) {
                        try {
                            val fileUri = writeSAFFileBytes(uriString, fileName, bytes, mimeType)
                            result.success(fileUri)
                        } catch (e: Exception) {
                            result.error("WRITE_FAILED", "Failed to write file: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI, fileName, and bytes are required", null)
                    }
                }
                "readFile" -> {
                    val fileUriString = call.argument<String>("fileUri")
                    if (fileUriString != null) {
                        try {
                            val content = readSAFFile(fileUriString)
                            result.success(content)
                        } catch (e: Exception) {
                            result.error("READ_FAILED", "Failed to read file: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "File URI is required", null)
                    }
                }
                "deleteFile" -> {
                    val fileUriString = call.argument<String>("fileUri")
                    if (fileUriString != null) {
                        try {
                            val success = deleteSAFFile(fileUriString)
                            result.success(success)
                        } catch (e: Exception) {
                            result.error("DELETE_FAILED", "Failed to delete file: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "File URI is required", null)
                    }
                }
                "validatePermissions" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val isValid = validateSAFPermissions(uriString)
                            result.success(isValid)
                        } catch (e: Exception) {
                            Log.e(TAG, "SAF permission validation failed: ${e.message}")
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI is required", null)
                    }
                }
                "getFolderDisplayName" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val displayName = getSAFFolderDisplayName(uriString)
                            result.success(displayName)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to get folder display name: ${e.message}")
                            result.success(null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Voice Capture channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_CAPTURE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> {
                    val available = SpeechRecognizer.isRecognitionAvailable(this)
                    result.success(available)
                }
                "hasPermission" -> {
                    val hasPermission = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECORD_AUDIO
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(hasPermission)
                }
                "requestPermission" -> {
                    val hasPermission = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECORD_AUDIO
                    ) == PackageManager.PERMISSION_GRANTED

                    if (hasPermission) {
                        result.success(true)
                    } else {
                        pendingPermissionResultHandler = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.RECORD_AUDIO),
                            PERMISSION_REQUEST_RECORD_AUDIO
                        )
                    }
                }
                "startListening" -> {
                    val promptHint = call.argument<String>("promptHint") ?: "Speak now"
                    val timeoutMs = call.argument<Int>("timeoutMs") ?: 30000
                    startVoiceCapture(result, promptHint, timeoutMs)
                }
                "stopListening" -> {
                    stopVoiceCapture()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Lock screen voice capture and hands-free mode channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCK_SCREEN_VOICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val handsFreeModeEnabled = call.argument<Boolean>("handsFreeModeEnabled") ?: false
                    startLockScreenVoiceService(handsFreeModeEnabled)
                    result.success(true)
                }
                "stopService" -> {
                    stopLockScreenVoiceService()
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(isLockScreenVoiceServiceRunning())
                }
                "enableHandsFree" -> {
                    enableHandsFreeMode()
                    result.success(true)
                }
                "disableHandsFree" -> {
                    disableHandsFreeMode()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // App Actions channel for Google Assistant integration
        appActionsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_ACTIONS_CHANNEL)

        // Cache Flutter engine for service communication
        FlutterEngineCache.getInstance().put(FLUTTER_ENGINE_ID, flutterEngine)
        Log.d(TAG, "Flutter engine cached for service communication")

        // Process any pending App Action that arrived before Flutter was ready
        pendingAppAction?.let { actionData ->
            Log.d(TAG, "Sending pending App Action to Flutter: $actionData")
            val actionType = actionData["action"] as? String
            when (actionType) {
                "log_food" -> appActionsChannel?.invokeMethod("logFood", actionData)
                "log_exercise" -> appActionsChannel?.invokeMethod("logExercise", actionData)
                "start_workout" -> appActionsChannel?.invokeMethod("startWorkout", actionData)
                "reflect" -> appActionsChannel?.invokeMethod("openReflect", actionData)
                "chat_mentor" -> appActionsChannel?.invokeMethod("openChatMentor", actionData)
                else -> appActionsChannel?.invokeMethod("createTodo", actionData)
            }
            pendingAppAction = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle intent that launched the activity
        handleAppActionIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Handle intent when activity is already running
        handleAppActionIntent(intent)
    }

    /// Handle incoming App Action intent from Google Assistant
    private fun handleAppActionIntent(intent: Intent?) {
        if (intent == null) return

        // Check for App Action parameters
        val todoTitle = intent.getStringExtra("todo_title")
        val todoDueDate = intent.getStringExtra("todo_due_date")
        val action = intent.getStringExtra("action")

        // Check if this is a CREATE_TASK action (from Google Assistant)
        // or a static shortcut action
        if (todoTitle != null || action == "add_todo") {
            Log.d(TAG, "App Action received - title: $todoTitle, dueDate: $todoDueDate, action: $action")

            val actionData = mapOf(
                "title" to (todoTitle ?: ""),
                "dueDate" to todoDueDate,
                "action" to (action ?: "create_task"),
                "source" to "google_assistant"
            )

            // If Flutter engine is ready, send immediately
            // Otherwise, store for later
            if (appActionsChannel != null) {
                Log.d(TAG, "Sending App Action to Flutter immediately")
                appActionsChannel?.invokeMethod("createTodo", actionData)
            } else {
                Log.d(TAG, "Flutter not ready, storing App Action for later")
                pendingAppAction = actionData
            }

            // Clear the intent extras to prevent re-processing
            intent.removeExtra("todo_title")
            intent.removeExtra("todo_due_date")
            intent.removeExtra("action")
        }

        // Check if this is a log_food shortcut action
        if (action == "log_food") {
            Log.d(TAG, "Log Food shortcut action received")

            val actionData = mapOf(
                "action" to "log_food",
                "source" to "shortcut"
            )

            // If Flutter engine is ready, send immediately
            // Otherwise, store for later
            if (appActionsChannel != null) {
                Log.d(TAG, "Sending Log Food action to Flutter immediately")
                appActionsChannel?.invokeMethod("logFood", actionData)
            } else {
                Log.d(TAG, "Flutter not ready, storing Log Food action for later")
                pendingAppAction = actionData
            }

            // Clear the intent extras to prevent re-processing
            intent.removeExtra("action")
        }

        // Check if this is a log_exercise shortcut action
        if (action == "log_exercise") {
            Log.d(TAG, "Log Exercise shortcut action received")

            val actionData = mapOf(
                "action" to "log_exercise",
                "source" to "shortcut"
            )

            if (appActionsChannel != null) {
                Log.d(TAG, "Sending Log Exercise action to Flutter immediately")
                appActionsChannel?.invokeMethod("logExercise", actionData)
            } else {
                Log.d(TAG, "Flutter not ready, storing Log Exercise action for later")
                pendingAppAction = actionData
            }

            intent.removeExtra("action")
        }

        // Check if this is a start_workout shortcut action
        if (action == "start_workout") {
            Log.d(TAG, "Start Workout shortcut action received")

            val actionData = mapOf(
                "action" to "start_workout",
                "source" to "shortcut"
            )

            if (appActionsChannel != null) {
                Log.d(TAG, "Sending Start Workout action to Flutter immediately")
                appActionsChannel?.invokeMethod("startWorkout", actionData)
            } else {
                Log.d(TAG, "Flutter not ready, storing Start Workout action for later")
                pendingAppAction = actionData
            }

            intent.removeExtra("action")
        }

        // Check if this is a reflect shortcut action
        if (action == "reflect") {
            Log.d(TAG, "Reflect shortcut action received")

            val actionData = mapOf(
                "action" to "reflect",
                "source" to "shortcut"
            )

            if (appActionsChannel != null) {
                Log.d(TAG, "Sending Reflect action to Flutter immediately")
                appActionsChannel?.invokeMethod("openReflect", actionData)
            } else {
                Log.d(TAG, "Flutter not ready, storing Reflect action for later")
                pendingAppAction = actionData
            }

            intent.removeExtra("action")
        }

        // Check if this is a chat_mentor shortcut action
        if (action == "chat_mentor") {
            Log.d(TAG, "Chat with Mentor shortcut action received")

            val actionData = mapOf(
                "action" to "chat_mentor",
                "source" to "shortcut"
            )

            if (appActionsChannel != null) {
                Log.d(TAG, "Sending Chat Mentor action to Flutter immediately")
                appActionsChannel?.invokeMethod("openChatMentor", actionData)
            } else {
                Log.d(TAG, "Flutter not ready, storing Chat Mentor action for later")
                pendingAppAction = actionData
            }

            intent.removeExtra("action")
        }
    }

    private fun checkOnDeviceAIAvailability(): Map<String, Any?> {
        val packageManager = packageManager
        val resultMap = mutableMapOf<String, Any?>()

        // Check if AICore package is installed
        var isAICoreInstalled = false
        var aicoreVersion: String? = null

        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(AICORE_PACKAGE, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(AICORE_PACKAGE, 0)
            }
            isAICoreInstalled = true
            aicoreVersion = packageInfo.versionName
        } catch (e: PackageManager.NameNotFoundException) {
            // AICore not installed
            isAICoreInstalled = false
        }

        // Check Android version (Android 14+ for better AICore support)
        val isSupported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE // Android 14+

        // For now, we can only check package installation
        // Actual Gemini Nano availability requires Google AI SDK integration
        val isGeminiNanoAvailable = isAICoreInstalled && isSupported

        resultMap["isAICoreInstalled"] = isAICoreInstalled
        resultMap["isGeminiNanoAvailable"] = isGeminiNanoAvailable
        resultMap["aicoreVersion"] = aicoreVersion
        resultMap["isSupported"] = isSupported
        resultMap["errorMessage"] = if (!isSupported) {
            "Android ${Build.VERSION.SDK_INT} detected. Android 14+ (API 34+) recommended for AICore support."
        } else null

        // Additional device info
        val additionalInfo = mutableMapOf<String, Any>()
        additionalInfo["androidVersion"] = Build.VERSION.SDK_INT
        additionalInfo["androidRelease"] = Build.VERSION.RELEASE
        additionalInfo["deviceModel"] = Build.MODEL
        additionalInfo["deviceManufacturer"] = Build.MANUFACTURER

        resultMap["additionalInfo"] = additionalInfo

        return resultMap
    }

    /// Validate LiteRT model without loading it into memory (check file exists and size)
    private suspend fun validateLiteRTModel(modelPath: String): Map<String, Any> = withContext(Dispatchers.IO) {
        try {
            val resultMap = mutableMapOf<String, Any>()

            // Check available memory
            val runtime = Runtime.getRuntime()
            val maxMemory = runtime.maxMemory()
            val usedMemory = runtime.totalMemory() - runtime.freeMemory()
            val availableMemory = maxMemory - usedMemory
            val availableMB = availableMemory / (1024 * 1024)

            Log.d(TAG, "Memory check - Available: ${availableMB}MB, Max: ${maxMemory / (1024 * 1024)}MB")

            // Check if model file exists
            val modelFile = File(modelPath)
            if (!modelFile.exists()) {
                throw Exception("Model file not found: $modelPath")
            }

            Log.d(TAG, "Validating LiteRT model from: $modelPath")
            val modelSize = modelFile.length()
            Log.d(TAG, "Model file size: $modelSize bytes (${modelSize / 1024 / 1024} MB)")

            resultMap["modelFileValid"] = true
            resultMap["modelSizeMB"] = modelSize / 1024 / 1024
            resultMap["availableMemoryMB"] = availableMB

            // LiteRT .task files include tokenization built-in
            resultMap["tokenizerLoaded"] = true

            resultMap["success"] = true
            resultMap["message"] = "Model file validated (size check passed, tokenizer built-in)"

            return@withContext resultMap

        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "OUT OF MEMORY during validation: ${e.message}", e)
            val errorMap = mutableMapOf<String, Any>()
            errorMap["success"] = false
            errorMap["message"] = "Out of memory - device cannot load this model"
            errorMap["error"] = "OutOfMemoryError: ${e.message}"
            return@withContext errorMap
        } catch (e: Throwable) {
            Log.e(TAG, "Validation failed: ${e.message}", e)
            val errorMap = mutableMapOf<String, Any>()
            errorMap["success"] = false
            errorMap["message"] = "Validation failed: ${e.message}"
            errorMap["error"] = e.message ?: "Unknown error"
            errorMap["errorType"] = e.javaClass.simpleName
            return@withContext errorMap
        }
    }

    /// Load LiteRT LLM model
    /// Heavy operation - runs on IO dispatcher to avoid blocking UI
    private suspend fun loadLiteRTModel(modelPath: String): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "=== LOAD MODEL START (LiteRT LLM) ===")
            Log.d(TAG, "Step 1: Acquiring model lock for cleanup")

            synchronized(modelLock) {
                // Close existing engine if any
                Log.d(TAG, "Step 2: Closing existing engine (if any)")
                try {
                    engine?.close()
                } catch (e: Exception) {
                    Log.w(TAG, "Error closing engine: ${e.message}")
                }
                engine = null
            }

            Log.d(TAG, "Step 3: Checking model file exists")
            val modelFile = File(modelPath)
            if (!modelFile.exists()) {
                Log.e(TAG, "ERROR: Model file not found: $modelPath")
                throw Exception("Model file not found: $modelPath")
            }

            Log.d(TAG, "Step 4: Model file found")
            Log.d(TAG, "Model path: $modelPath")
            Log.d(TAG, "Model file size: ${modelFile.length()} bytes (${modelFile.length() / 1024 / 1024} MB)")

            Log.d(TAG, "Step 5: Building LiteRT Engine configuration")
            // Create LiteRT Engine configuration
            val engineConfig = EngineConfig(
                modelPath = modelPath,
                backend = Backend.GPU,  // Use GPU backend with OpenCL for better performance
                maxNumTokens = 1024     // Maximum tokens for responses (~700-800 words)
                                        // Context window is 2048 tokens (determined by ekv2048 model variant)
                                        // Leaves ~1024 tokens for input context (prompts, minimal user data)
                                        // NOTE: Guided journaling prompts can be 500-800 tokens, so this
                                        // allocation prioritizes complete responses over extensive context
            )

            Log.d(TAG, "Step 6: Configuration built successfully")
            Log.d(TAG, "Step 7: Creating Engine instance (THIS MAY TAKE A WHILE)")
            Log.d(TAG, "NOTE: Using LiteRT LLM (official Google AI Edge library)")

            // Create Engine instance
            val newEngine = try {
                Engine(engineConfig)
            } catch (e: Exception) {
                Log.e(TAG, "LiteRT Engine creation failed!")
                Log.e(TAG, "This usually means the model format is incompatible")
                Log.e(TAG, "Error details: ${e.message}", e)
                throw Exception("Model incompatible with LiteRT on this device: ${e.message}")
            }

            Log.d(TAG, "Step 8: Initializing Engine")
            newEngine.initialize()

            Log.d(TAG, "Step 9: Storing engine instance with lock")
            // Note: We'll create a fresh Conversation for each inference to avoid context buildup
            synchronized(modelLock) {
                engine = newEngine
            }

            Log.d(TAG, "Step 10: Model loaded and ready successfully")
            Log.d(TAG, "=== LOAD MODEL COMPLETE (LiteRT LLM) ===")

            true
        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "OUT OF MEMORY loading model!", e)
            Log.e(TAG, "OOM Details: ${e.message}")
            synchronized(modelLock) {
                try {
                    engine?.close()
                } catch (ex: Exception) {
                    Log.w(TAG, "Error closing engine during OOM cleanup: ${ex.message}")
                }
                engine = null
            }
            throw Exception("Out of memory loading model: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "EXCEPTION loading model: ${e.javaClass.simpleName}", e)
            Log.e(TAG, "Exception message: ${e.message}")
            synchronized(modelLock) {
                try {
                    engine?.close()
                } catch (ex: Exception) {
                    Log.w(TAG, "Error closing engine during exception cleanup: ${ex.message}")
                }
                engine = null
            }
            throw Exception("Failed to load model: ${e.message}")
        } catch (e: Throwable) {
            Log.e(TAG, "THROWABLE loading model: ${e.javaClass.simpleName}", e)
            Log.e(TAG, "Throwable message: ${e.message}")
            synchronized(modelLock) {
                try {
                    engine?.close()
                } catch (ex: Exception) {
                    Log.w(TAG, "Error closing engine during throwable cleanup: ${ex.message}")
                }
                engine = null
            }
            throw Exception("Critical error loading model: ${e.message}")
        }
    }

    /// Run inference using LiteRT LLM
    /// Heavy operation - runs on IO dispatcher to avoid blocking UI
    /// Creates a fresh conversation for each inference to avoid context accumulation
    private suspend fun runInference(prompt: String): String = withContext(Dispatchers.IO) {
        var conversation: Conversation? = null
        try {
            Log.d(TAG, "=== RUN INFERENCE START (LiteRT LLM) ===")
            Log.d(TAG, "Inference Step 1: Acquiring model lock")

            val currentEngine = synchronized(modelLock) {
                Log.d(TAG, "Inference Step 2: Checking if engine is loaded")
                engine ?: throw Exception("Model not loaded. Call loadModel first.")
            }

            Log.d(TAG, "Inference Step 3: Creating fresh conversation for this inference")
            // Create a new conversation for each inference to avoid context buildup
            // This ensures each request starts with a clean slate
            conversation = currentEngine.createConversation(
                ConversationConfig(
                    samplerConfig = SamplerConfig(
                        topK = 40,
                        topP = 0.90,        // Slightly more focused (was 0.95)
                        temperature = 0.6   // Lower temperature = more concise, focused responses
                                           // 0.6 balances warmth/personality with brevity
                                           // (was 0.8 - too creative/verbose)
                    )
                )
            )

            Log.d(TAG, "Inference Step 4: Running inference for prompt: ${prompt.take(50)}...")
            Log.d(TAG, "Inference Step 5: Calling sendMessage (THIS MAY TAKE A WHILE)")

            // LiteRT handles tokenization automatically!
            // Send message and get response synchronously
            val message = Message.of(Content.Text(prompt))
            val responseMessage = conversation.sendMessage(message)

            // Extract text from response
            val responseText = responseMessage.contents
                .filterIsInstance<Content.Text>()
                .joinToString("") { it.text }

            Log.d(TAG, "Inference Step 6: sendMessage returned successfully!")
            Log.d(TAG, "Inference Step 7: Generated ${responseText.length} characters")
            Log.d(TAG, "Inference Step 8: Closing conversation")

            // Clean up the conversation after use
            conversation.close()

            Log.d(TAG, "=== RUN INFERENCE COMPLETE (LiteRT LLM) ===")

            responseText.trim()

        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "OUT OF MEMORY during inference!", e)
            Log.e(TAG, "OOM Details: ${e.message}")
            // Clean up conversation on error
            try {
                conversation?.close()
            } catch (ex: Exception) {
                Log.w(TAG, "Error closing conversation during OOM cleanup: ${ex.message}")
            }
            throw Exception("Out of memory during inference: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "EXCEPTION during inference: ${e.javaClass.simpleName}", e)
            Log.e(TAG, "Exception message: ${e.message}")
            // Clean up conversation on error
            try {
                conversation?.close()
            } catch (ex: Exception) {
                Log.w(TAG, "Error closing conversation during exception cleanup: ${ex.message}")
            }
            throw Exception("Inference failed: ${e.message}")
        } catch (e: Throwable) {
            Log.e(TAG, "THROWABLE during inference: ${e.javaClass.simpleName}", e)
            Log.e(TAG, "Throwable message: ${e.message}")
            // Clean up conversation on error
            try {
                conversation?.close()
            } catch (ex: Exception) {
                Log.w(TAG, "Error closing conversation during throwable cleanup: ${ex.message}")
            }
            throw Exception("Critical error during inference: ${e.message}")
        }
    }

    /// Unload LiteRT model to free memory
    private fun unloadLiteRTModel() {
        synchronized(modelLock) {
            try {
                engine?.close()
            } catch (e: Exception) {
                Log.w(TAG, "Error closing engine: ${e.message}")
            }
            engine = null
        }
        Log.d(TAG, "LiteRT model unloaded")
    }

    //
    // Storage Access Framework (SAF) Methods
    //

    /// Request folder access from user via system picker
    private fun requestFolderAccess(result: MethodChannel.Result) {
        safResultHandler = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            // Suggest Downloads folder as starting location
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI)
            }
        }
        startActivityForResult(intent, REQUEST_CODE_OPEN_DOCUMENT_TREE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE_OPEN_DOCUMENT_TREE && safResultHandler != null) {
            if (resultCode == Activity.RESULT_OK) {
                data?.data?.let { uri ->
                    // Take persistable URI permission
                    val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    contentResolver.takePersistableUriPermission(uri, takeFlags)

                    Log.d(TAG, "SAF folder access granted: $uri")
                    safResultHandler?.success(uri.toString())
                } ?: safResultHandler?.error("NO_URI", "No URI returned", null)
            } else {
                safResultHandler?.error("CANCELLED", "User cancelled folder selection", null)
            }
            safResultHandler = null
        }
    }

    /// List files in SAF directory
    private fun listSAFFiles(uriString: String): List<Map<String, Any>> {
        val treeUri = Uri.parse(uriString)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri)
        )

        val files = mutableListOf<Map<String, Any>>()

        contentResolver.query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_SIZE,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                DocumentsContract.Document.COLUMN_MIME_TYPE
            ),
            null,
            null,
            "${DocumentsContract.Document.COLUMN_LAST_MODIFIED} DESC"
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val documentId = cursor.getString(0)
                val displayName = cursor.getString(1)
                val size = cursor.getLong(2)
                val lastModified = cursor.getLong(3)
                val mimeType = cursor.getString(4)

                // Only include JSON files
                if (displayName.endsWith(".json")) {
                    val documentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
                    files.add(mapOf(
                        "uri" to documentUri.toString(),
                        "name" to displayName,
                        "size" to size,
                        "lastModified" to lastModified,
                        "mimeType" to (mimeType ?: "application/json")
                    ))
                }
            }
        }

        return files
    }

    /// Write file to SAF directory
    private fun writeSAFFile(uriString: String, fileName: String, content: String): String {
        val treeUri = Uri.parse(uriString)
        val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
        val parentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, treeDocumentId)

        // Create new document
        val newFileUri = DocumentsContract.createDocument(
            contentResolver,
            parentUri,
            "application/json",
            fileName
        ) ?: throw Exception("Failed to create document")

        // Write content
        contentResolver.openOutputStream(newFileUri)?.use { outputStream ->
            outputStream.write(content.toByteArray())
        } ?: throw Exception("Failed to open output stream")

        Log.d(TAG, "SAF file written: $fileName")
        return newFileUri.toString()
    }

    /// Write binary file to SAF directory (for ZIP backups)
    private fun writeSAFFileBytes(uriString: String, fileName: String, bytes: ByteArray, mimeType: String): String {
        val treeUri = Uri.parse(uriString)
        val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
        val parentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, treeDocumentId)

        // Create new document with specified MIME type
        val newFileUri = DocumentsContract.createDocument(
            contentResolver,
            parentUri,
            mimeType,
            fileName
        ) ?: throw Exception("Failed to create document")

        // Write binary content
        contentResolver.openOutputStream(newFileUri)?.use { outputStream ->
            outputStream.write(bytes)
        } ?: throw Exception("Failed to open output stream")

        Log.d(TAG, "SAF binary file written: $fileName (${bytes.size} bytes)")
        return newFileUri.toString()
    }

    /// Read file from SAF URI
    private fun readSAFFile(fileUriString: String): String {
        val fileUri = Uri.parse(fileUriString)

        contentResolver.openInputStream(fileUri)?.use { inputStream ->
            return inputStream.bufferedReader().use { it.readText() }
        } ?: throw Exception("Failed to open input stream")
    }

    /// Delete file from SAF URI
    private fun deleteSAFFile(fileUriString: String): Boolean {
        val fileUri = Uri.parse(fileUriString)
        return DocumentsContract.deleteDocument(contentResolver, fileUri)
    }

    /// Validate that we have persistable permissions for the given SAF URI
    /// This is important after fresh install when URI may be restored from backup
    /// but the actual SAF permission grant is gone (permissions are installation-specific)
    private fun validateSAFPermissions(uriString: String): Boolean {
        val uri = Uri.parse(uriString)

        // Check if we have this URI in our persisted permissions
        val persistedPermissions = contentResolver.persistedUriPermissions
        val hasPermission = persistedPermissions.any { permission ->
            permission.uri == uri && permission.isReadPermission && permission.isWritePermission
        }

        if (!hasPermission) {
            Log.d(TAG, "SAF permission validation failed: URI not in persisted permissions")
            return false
        }

        // Additional check: try to query the folder to verify access actually works
        try {
            val treeUri = uri
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri)
            )

            contentResolver.query(
                childrenUri,
                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
                null,
                null,
                null
            )?.use { cursor ->
                // Successfully queried - permissions are valid
                Log.d(TAG, "SAF permission validation passed: can access folder")
                return true
            }

            Log.d(TAG, "SAF permission validation failed: query returned null")
            return false
        } catch (e: SecurityException) {
            Log.d(TAG, "SAF permission validation failed with SecurityException: ${e.message}")
            return false
        } catch (e: Exception) {
            Log.e(TAG, "SAF permission validation error: ${e.message}")
            return false
        }
    }

    /// Get a human-readable display name/path for the SAF folder URI
    /// Returns a path like "Downloads" or "Documents/Backups" based on the URI
    private fun getSAFFolderDisplayName(uriString: String): String? {
        val uri = Uri.parse(uriString)

        try {
            val treeDocumentId = DocumentsContract.getTreeDocumentId(uri)
            val documentUri = DocumentsContract.buildDocumentUriUsingTree(uri, treeDocumentId)

            // Query for the display name of the folder
            contentResolver.query(
                documentUri,
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val displayName = cursor.getString(0)
                    Log.d(TAG, "SAF folder display name: $displayName")
                    return displayName
                }
            }

            // Fallback: try to extract a meaningful path from the URI
            // URI typically looks like: content://com.android.externalstorage.documents/tree/primary:Downloads
            val path = treeDocumentId.substringAfter(":", "")
            if (path.isNotEmpty()) {
                Log.d(TAG, "SAF folder path from URI: $path")
                return path
            }

            return null
        } catch (e: Exception) {
            Log.e(TAG, "Error getting SAF folder display name: ${e.message}")
            return null
        }
    }

    //
    // Voice Capture Methods
    //

    /// Start voice capture using Android Speech Recognition
    private fun startVoiceCapture(result: MethodChannel.Result, promptHint: String, timeoutMs: Int) {
        // Check permission first
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "Microphone permission not granted", null)
            return
        }

        // Check if speech recognition is available
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            result.error("NOT_AVAILABLE", "Speech recognition not available on this device", null)
            return
        }

        // Cancel any existing recognizer
        stopVoiceCapture()

        voiceCaptureResultHandler = result

        // Create speech recognizer on main thread
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    Log.d(TAG, "Voice capture: Ready for speech")
                }

                override fun onBeginningOfSpeech() {
                    Log.d(TAG, "Voice capture: Beginning of speech detected")
                }

                override fun onRmsChanged(rmsdB: Float) {
                    // Audio level changed - can be used for visual feedback
                }

                override fun onBufferReceived(buffer: ByteArray?) {
                    // Partial sound buffer received
                }

                override fun onEndOfSpeech() {
                    Log.d(TAG, "Voice capture: End of speech detected")
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
                    Log.e(TAG, "Voice capture error: $errorMessage")

                    // For "no match" - return null instead of error (user may not have spoken)
                    if (error == SpeechRecognizer.ERROR_NO_MATCH ||
                        error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT) {
                        voiceCaptureResultHandler?.success(null)
                    } else {
                        voiceCaptureResultHandler?.error("SPEECH_ERROR", errorMessage, null)
                    }
                    voiceCaptureResultHandler = null
                    cleanupSpeechRecognizer()
                }

                override fun onResults(results: Bundle?) {
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val transcript = matches?.firstOrNull()

                    Log.d(TAG, "Voice capture result: $transcript")

                    voiceCaptureResultHandler?.success(transcript)
                    voiceCaptureResultHandler = null
                    cleanupSpeechRecognizer()
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    // Partial recognition results
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    Log.d(TAG, "Voice capture partial: ${matches?.firstOrNull()}")
                }

                override fun onEvent(eventType: Int, params: Bundle?) {
                    // Reserved for future use
                }
            })
        }

        // Create intent for speech recognition
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_PROMPT, promptHint)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 3000)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1500)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 1500)
        }

        Log.d(TAG, "Voice capture: Starting speech recognition")
        speechRecognizer?.startListening(intent)
    }

    /// Stop voice capture
    private fun stopVoiceCapture() {
        try {
            speechRecognizer?.cancel()
            cleanupSpeechRecognizer()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping voice capture: ${e.message}")
        }
    }

    /// Clean up speech recognizer resources
    private fun cleanupSpeechRecognizer() {
        try {
            speechRecognizer?.destroy()
        } catch (e: Exception) {
            Log.w(TAG, "Error destroying speech recognizer: ${e.message}")
        }
        speechRecognizer = null
    }

    //
    // Lock Screen Voice Service Methods
    //

    /// Track if service is running
    private var lockScreenServiceRunning = false

    /// Start the lock screen voice capture foreground service
    private fun startLockScreenVoiceService(handsFreeModeEnabled: Boolean = false) {
        try {
            val serviceIntent = Intent(this, VoiceCaptureService::class.java).apply {
                action = VoiceCaptureService.ACTION_START_SERVICE
                putExtra(VoiceCaptureService.EXTRA_HANDS_FREE_ENABLED, handsFreeModeEnabled)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }

            lockScreenServiceRunning = true
            Log.d(TAG, "Lock screen voice service started (handsFreeModeEnabled: $handsFreeModeEnabled)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start lock screen voice service: ${e.message}")
        }
    }

    /// Stop the lock screen voice capture foreground service
    private fun stopLockScreenVoiceService() {
        try {
            val serviceIntent = Intent(this, VoiceCaptureService::class.java).apply {
                action = VoiceCaptureService.ACTION_STOP_SERVICE
            }
            startService(serviceIntent)
            lockScreenServiceRunning = false
            Log.d(TAG, "Lock screen voice service stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop lock screen voice service: ${e.message}")
        }
    }

    /// Check if the lock screen voice service is running
    private fun isLockScreenVoiceServiceRunning(): Boolean {
        return lockScreenServiceRunning
    }

    /// Enable hands-free mode (Bluetooth button trigger + TTS feedback)
    private fun enableHandsFreeMode() {
        try {
            val serviceIntent = Intent(this, VoiceCaptureService::class.java).apply {
                action = VoiceCaptureService.ACTION_ENABLE_HANDS_FREE
            }
            startService(serviceIntent)
            Log.d(TAG, "Hands-free mode enabled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enable hands-free mode: ${e.message}")
        }
    }

    /// Disable hands-free mode
    private fun disableHandsFreeMode() {
        try {
            val serviceIntent = Intent(this, VoiceCaptureService::class.java).apply {
                action = VoiceCaptureService.ACTION_DISABLE_HANDS_FREE
            }
            startService(serviceIntent)
            Log.d(TAG, "Hands-free mode disabled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disable hands-free mode: ${e.message}")
        }
    }

    /// Handle permission request result
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == PERMISSION_REQUEST_RECORD_AUDIO) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResultHandler?.success(granted)
            pendingPermissionResultHandler = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unloadLiteRTModel()
        cleanupSpeechRecognizer()
    }
}
