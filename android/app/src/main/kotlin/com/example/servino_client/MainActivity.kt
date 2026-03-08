package com.example.servino_client

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.app/intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "openDeveloperOptions" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                    if (intent.resolveActivity(packageManager) != null) {
                        startActivity(intent)
                        result.success(null)
                    } else {
                        startActivity(Intent(Settings.ACTION_SETTINGS))
                        result.success(null)
                    }
                }
                "checkDeveloperOptions" -> {
                    val devOptions = Settings.Global.getInt(contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0)
                    result.success(devOptions != 0)
                }
                "checkAdbEnabled" -> {
                    val adbEnabled = Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0)
                    result.success(adbEnabled != 0)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
