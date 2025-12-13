package com.example.ai_mentor_coach

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.KeyEvent

/**
 * BroadcastReceiver for handling media button events from Bluetooth headsets,
 * car systems, and wired headsets.
 *
 * Enables hands-free voice recording while driving - user presses headset button
 * to start voice capture without looking at the phone.
 */
class MediaButtonReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "MediaButtonReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_MEDIA_BUTTON != intent.action) {
            return
        }

        val event = intent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
        if (event == null) {
            Log.d(TAG, "No key event in media button intent")
            return
        }

        // Only handle key down events to avoid duplicate triggers
        if (event.action != KeyEvent.ACTION_DOWN) {
            return
        }

        Log.d(TAG, "Media button pressed: keyCode=${event.keyCode}")

        // Handle various media button key codes
        when (event.keyCode) {
            KeyEvent.KEYCODE_HEADSETHOOK,      // Single button headset (play/pause)
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, // Play/pause button
            KeyEvent.KEYCODE_MEDIA_PLAY,       // Play button
            KeyEvent.KEYCODE_MEDIA_PAUSE -> {  // Pause button
                Log.d(TAG, "Triggering voice capture from media button")
                triggerVoiceCapture(context)
            }
            else -> {
                Log.d(TAG, "Ignoring media button keyCode: ${event.keyCode}")
            }
        }
    }

    private fun triggerVoiceCapture(context: Context) {
        // Send intent to VoiceCaptureService to start recording
        val serviceIntent = Intent(context, VoiceCaptureService::class.java).apply {
            action = VoiceCaptureService.ACTION_START_VOICE_CAPTURE
        }

        try {
            context.startService(serviceIntent)
            Log.d(TAG, "Voice capture service started from media button")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start voice capture service: ${e.message}")
        }
    }
}
