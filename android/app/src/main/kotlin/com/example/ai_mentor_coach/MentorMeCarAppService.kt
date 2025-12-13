package com.example.ai_mentor_coach

import android.content.Intent
import android.content.pm.ApplicationInfo
import androidx.car.app.CarAppService
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.car.app.SessionInfo
import androidx.car.app.validation.HostValidator

/**
 * Android Auto CarAppService for MentorMe.
 * Provides hands-free voice todo creation while driving.
 *
 * Entry point for Android Auto - the system calls this service
 * when the user connects to Android Auto.
 */
class MentorMeCarAppService : CarAppService() {

    override fun createHostValidator(): HostValidator {
        // For development/sideloading, allow all hosts
        // For production Play Store apps, use ALLOW_ALL_HOSTS_VALIDATOR
        // or specify specific host package names for security
        return if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
        } else {
            // In production, you might want to restrict to specific hosts:
            // HostValidator.Builder(applicationContext)
            //     .addAllowedHosts(androidx.car.app.R.array.hosts_allowlist_sample)
            //     .build()
            HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
        }
    }

    override fun onCreateSession(sessionInfo: SessionInfo): Session {
        return MentorMeSession()
    }
}

/**
 * Session for MentorMe Android Auto app.
 * Creates and manages the screens shown on the car display.
 */
class MentorMeSession : Session() {

    override fun onCreateScreen(intent: Intent): Screen {
        return VoiceTodoScreen(carContext)
    }
}
