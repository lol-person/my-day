package com.example.productivity_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { updateWidget(context, appWidgetManager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    private fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ) {
        val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
        val savedDay = preferences.getString(KEY_DAY, null)
        val currentDay = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val isCurrentDay = savedDay == currentDay
        val totalHabits = if (isCurrentDay) preferences.getInt(KEY_TOTAL_HABITS, 0) else 0
        val completedHabits = if (isCurrentDay) {
            preferences.getInt(KEY_COMPLETED_HABITS, 0).coerceIn(0, totalHabits)
        } else {
            0
        }
        val activeTasks = if (isCurrentDay) preferences.getInt(KEY_ACTIVE_TASKS, 0) else 0
        val progress = if (totalHabits == 0) 0 else completedHabits * 100 / totalHabits
        val views = RemoteViews(context.packageName, R.layout.today_widget)

        views.setTextViewText(R.id.today_widget_habits_value, "$completedHabits/$totalHabits")
        views.setTextViewText(R.id.today_widget_tasks_value, activeTasks.toString())
        views.setTextViewText(R.id.today_widget_progress_value, "$progress%")
        views.setProgressBar(R.id.today_widget_progress_bar, 100, progress, false)
        views.setTextViewText(
            R.id.today_widget_status,
            if (totalHabits == 0 && activeTasks == 0) {
                context.getString(R.string.today_widget_empty)
            } else {
                context.getString(R.string.today_widget_subtitle)
            },
        )
        views.setContentDescription(
            R.id.today_widget_habits,
            context.getString(
                R.string.today_widget_habits_description,
                completedHabits,
                totalHabits,
            ),
        )
        views.setContentDescription(
            R.id.today_widget_tasks,
            context.getString(R.string.today_widget_tasks_description, activeTasks),
        )
        views.setContentDescription(
            R.id.today_widget_progress,
            context.getString(R.string.today_widget_progress_description, progress),
        )
        views.setOnClickPendingIntent(
            R.id.today_widget_habits,
            screenPendingIntent(context, TARGET_HABITS, REQUEST_HABITS),
        )
        views.setOnClickPendingIntent(
            R.id.today_widget_tasks,
            screenPendingIntent(context, TARGET_TASKS, REQUEST_TASKS),
        )
        views.setOnClickPendingIntent(
            R.id.today_widget_progress,
            screenPendingIntent(context, TARGET_STATISTICS, REQUEST_STATISTICS),
        )

        manager.updateAppWidget(widgetId, views)
    }

    private fun screenPendingIntent(context: Context, target: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_OPEN_WIDGET_TARGET
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_WIDGET_TARGET, target)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        private const val PREFERENCES_NAME = "today_widget_snapshot"
        private const val KEY_DAY = "day"
        private const val KEY_COMPLETED_HABITS = "completed_habits"
        private const val KEY_TOTAL_HABITS = "total_habits"
        private const val KEY_ACTIVE_TASKS = "active_tasks"
        private const val ACTION_OPEN_WIDGET_TARGET = "com.example.productivity_app.OPEN_WIDGET_TARGET"
        private const val TARGET_HABITS = "habits"
        private const val TARGET_TASKS = "tasks"
        private const val TARGET_STATISTICS = "statistics"
        private const val REQUEST_HABITS = 741
        private const val REQUEST_TASKS = 742
        private const val REQUEST_STATISTICS = 743

        fun update(
            context: Context,
            completedHabits: Int,
            totalHabits: Int,
            activeTasks: Int,
        ) {
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(
                    KEY_DAY,
                    SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date()),
                )
                .putInt(KEY_COMPLETED_HABITS, completedHabits.coerceAtLeast(0))
                .putInt(KEY_TOTAL_HABITS, totalHabits.coerceAtLeast(0))
                .putInt(KEY_ACTIVE_TASKS, activeTasks.coerceAtLeast(0))
                .apply()

            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, TodayWidgetProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            TodayWidgetProvider().onUpdate(context, manager, widgetIds)
        }
    }
}
