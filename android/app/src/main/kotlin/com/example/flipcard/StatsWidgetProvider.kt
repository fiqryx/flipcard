package com.example.flipcard

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class StatsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)

        val totalQuiz = widgetData.getInt("total_quiz", 0) ?: 0
        val accuracy = widgetData.getString("accuracy", "0") ?: "0"
        val currentStreak = widgetData.getInt("current_streak", 0) ?: 0

        val views = RemoteViews(context.packageName, R.layout.stats_split_widget)

        // quiz completed
        // views.setTextViewText(R.id.widget_message_1, message)
        views.setTextViewText(R.id.widget_counter_1, totalQuiz.toString())

        // accuracy
        // views.setTextViewText(R.id.widget_message_2, message)
        views.setTextViewText(R.id.widget_counter_2, accuracy)

        // current streak
        // views.setTextViewText(R.id.widget_message_3, message)
        views.setTextViewText(R.id.widget_counter_3, currentStreak.toString())

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
