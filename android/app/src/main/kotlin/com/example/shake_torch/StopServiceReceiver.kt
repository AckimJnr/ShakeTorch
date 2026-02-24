package com.example.shake_torch

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.ComponentName
import id.flutter.flutter_background_service.BackgroundService

class StopServiceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Stop the Flutter background service
        val stopIntent = Intent(context, BackgroundService::class.java)
        context.stopService(stopIntent)
    }
}
