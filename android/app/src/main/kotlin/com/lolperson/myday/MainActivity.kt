package com.lolperson.myday

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var todayWidgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        )
        todayWidgetChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateToday" -> {
                    val values = call.arguments as? Map<*, *>
                    val totalHabits = values?.get("totalHabits") as? Int ?: 0
                    val completedHabits =
                        (values?.get("completedHabits") as? Int ?: 0)
                            .coerceIn(0, totalHabits.coerceAtLeast(0))
                    val activeTasks =
                        (values?.get("activeTasks") as? Int ?: 0).coerceAtLeast(0)
                    val progress = if (totalHabits == 0) {
                        0
                    } else {
                        completedHabits * 100 / totalHabits
                    }
                    TodayWidgetProvider.update(
                        this,
                        completedHabits,
                        totalHabits.coerceAtLeast(0),
                        activeTasks,
                    )
                    result.success(null)
                }
                "getInitialTarget" -> {
                    val target = intent?.getStringExtra(EXTRA_WIDGET_TARGET)
                    intent?.removeExtra(EXTRA_WIDGET_TARGET)
                    result.success(target)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val target = intent.getStringExtra(EXTRA_WIDGET_TARGET)
        if (target != null) {
            intent.removeExtra(EXTRA_WIDGET_TARGET)
            todayWidgetChannel?.invokeMethod("openTarget", target)
        }
    }

    companion object {
        const val CHANNEL_NAME = "com.lolperson.myday/today_widget"
        const val EXTRA_WIDGET_TARGET = "today_widget_target"
    }
}
