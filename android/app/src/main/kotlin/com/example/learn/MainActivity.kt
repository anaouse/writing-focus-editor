// android/app/src/main/kotlin/com/example/learn/MainActivity.kt
package com.example.learn

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.notes.app/shortcut"
    private var methodChannel: MethodChannel? = null

    // 暂存从快捷方式启动时的文件路径
    private var initialNotePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "createShortcut" -> {
                    val filePath = call.argument<String>("filePath")
                    val noteName = call.argument<String>("noteName")
                    
                    if (filePath != null && noteName != null) {
                        val success = createShortcut(filePath, noteName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGS", "Missing filePath or noteName", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // 在引擎配置完成后，检查是否有暂存的路径如果有，就发送给 Flutter，并清空它，防止重复发送
        initialNotePath?.let { path ->
            methodChannel?.invokeMethod("openNote", path)
            initialNotePath = null
        }
    }
    // 应用冷启动时调用
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }
    // 应用已在后台，快捷方式启动时调用
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "OPEN_NOTE") {
            val filePath = intent.getStringExtra("FILE_PATH")
            if (filePath != null) {
                // 如果Flutter引擎已经准备好了, 直接调用, 如果没有说明是冷启动, 就存到initialNotePath中
                if (flutterEngine != null) {
                    methodChannel?.invokeMethod("openNote", filePath)
                } else {
                    initialNotePath = filePath
                }
            }
        }
    }
    // 确保支持快捷方式的系统下, 创建快捷方式, 需要手动赋予权限
    private fun createShortcut(filePath: String, noteName: String): Boolean {
        return try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val shortcutManager = getSystemService(android.content.pm.ShortcutManager::class.java)
                
                if (shortcutManager?.isRequestPinShortcutSupported == true) {
                    //MainActivity::class.java 表示点击快捷方式时，会启动 MainActivity
                    val intent = Intent(this, MainActivity::class.java).apply {
                        action = "OPEN_NOTE"
                        putExtra("FILE_PATH", filePath)
                        flags = Intent.FLAG_ACTIVITY_SINGLE_TOP // 如果Activity已经在顶部，就不会重新创建
                    }
                    val iconResId = applicationInfo.icon
                    val shortcut = android.content.pm.ShortcutInfo.Builder(this, "note_$filePath")
                        .setShortLabel(noteName)
                        .setLongLabel("打开笔记: $noteName")
                        .setIcon(android.graphics.drawable.Icon.createWithResource(this, iconResId))
                        .setIntent(intent)
                        .build()
                    shortcutManager.requestPinShortcut(shortcut, null)
                    true
                } else {
                    false
                }
            }
            else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}