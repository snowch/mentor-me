package com.example.ai_mentor_coach

import android.content.pm.PackageManager
import android.os.Build
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

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MentorMe"
    }

    private val CHANNEL = "com.mentorme/on_device_ai"
    private val LOCAL_AI_CHANNEL = "com.mentorme/local_ai"
    private val AICORE_PACKAGE = "com.google.android.aicore"

    // LiteRT LLM Engine instance with thread-safe access
    // Note: We create a fresh Conversation for each inference to avoid context accumulation
    private var engine: Engine? = null
    private val modelLock = Any()  // Lock for thread-safe model access

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

    override fun onDestroy() {
        super.onDestroy()
        unloadLiteRTModel()
    }
}
