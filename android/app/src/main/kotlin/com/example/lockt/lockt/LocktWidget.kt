package com.example.lockt.lockt

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class LocktWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.lockt_widget)
            
            val status = widgetData.getString("status", "No Routine")
            views.setTextViewText(R.id.widget_status_text, status)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
