package app.iconstudio.icon_studio

import android.app.Activity
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.os.Bundle
import android.widget.*
import org.json.JSONObject
import java.io.File

object WidgetIcons {
    fun prefs(c: Context) = c.getSharedPreferences("icon_widgets", Context.MODE_PRIVATE)
    fun design(c: Context, id: String): JSONObject? = try { prefs(c).getString("design:$id", null)?.let { JSONObject(it) } } catch (_: Exception) { null }
    /** Mimics the visible center crop + circular launcher mask of our native adaptive icon. */
    fun renderWidgetBitmap(
        source: Bitmap, background: Int, background2: Int = background,
        gradient: Boolean = false, angle: Double = 0.0
    ): Bitmap {
        val visible = 192
        val adaptive = LauncherIcon.render(source, visible, visible, background, background2, gradient, angle)
        val output = Bitmap.createBitmap(visible, visible, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        canvas.drawCircle(visible / 2f, visible / 2f, visible / 2f, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        val inset = (adaptive.width - visible) / 2
        canvas.drawBitmap(
            adaptive,
            Rect(inset, inset, inset + visible, inset + visible),
            Rect(0, 0, visible, visible),
            paint
        )
        paint.xfermode = null
        adaptive.recycle()
        return output
    }

    fun store(
        c: Context, id: String, name: String, pkg: String, bytes: ByteArray,
        background: Int = Color.BLACK, background2: Int = background,
        gradient: Boolean = false, angle: Double = 0.0
    ) {
        require(id.matches(Regex("[0-9]+")))
        val source = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?: throw IllegalArgumentException("Image de widget invalide")
        val icon = try {
            renderWidgetBitmap(source, background, background2, gradient, angle)
        } finally {
            source.recycle()
        }
        val file = File(File(c.filesDir, "widget_icons").apply { mkdirs() }, "$id.png")
        val tmp = File(file.path + ".tmp")
        try {
            tmp.outputStream().use { require(icon.compress(Bitmap.CompressFormat.PNG, 100, it)) }
        } finally {
            icon.recycle()
        }
        check(tmp.renameTo(file)) { "Impossible de sauvegarder le widget" }
        prefs(c).edit().putString(
            "design:$id",
            JSONObject().put("name", name).put("package", pkg).put("path", file.path).toString()
        ).commit()
        val manager = AppWidgetManager.getInstance(c)
        for (widgetId in manager.getAppWidgetIds(ComponentName(c, IconWidgetProvider::class.java))) {
            if (prefs(c).getString("widget:$widgetId", null) == id) update(c, widgetId)
        }
    }
    fun views(c: Context, id: String?): RemoteViews {
        val views=RemoteViews(c.packageName,R.layout.icon_widget)
        val data=id?.let { design(c,it) }
        if (data==null) {
            views.setImageViewResource(R.id.widget_icon,R.mipmap.ic_launcher)
            views.setViewVisibility(R.id.widget_label,android.view.View.VISIBLE)
            views.setTextViewText(R.id.widget_label,"Choisir une icône")
        } else {
            val bitmap=BitmapFactory.decodeFile(data.optString("path"))
            if(bitmap!=null) views.setImageViewBitmap(R.id.widget_icon,bitmap)
            views.setTextViewText(R.id.widget_label,data.optString("name"))
            views.setViewVisibility(R.id.widget_label,android.view.View.VISIBLE)
        }
        return views
    }
    fun update(c: Context, widgetId: Int) {
        val id=prefs(c).getString("widget:$widgetId",null)
        val data=id?.let { design(c,it) }
        val views=views(c,id)
        val target=if(data==null) Intent(c,WidgetConfigActivity::class.java).putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,widgetId)
            else Intent(c,ShortcutLaunchActivity::class.java).setAction(Intent.ACTION_VIEW).putExtra("target_package",data.optString("package"))
        target.flags=Intent.FLAG_ACTIVITY_NEW_TASK
        val click=PendingIntent.getActivity(c,widgetId,target,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.widget_root,click)
        AppWidgetManager.getInstance(c).updateAppWidget(widgetId,views)
    }
    fun bind(c: Context, widgetId: Int, id: String) {
        if (widgetId==AppWidgetManager.INVALID_APPWIDGET_ID || design(c,id)==null) return
        val info=AppWidgetManager.getInstance(c).getAppWidgetInfo(widgetId) ?: return
        if(info.provider!=ComponentName(c,IconWidgetProvider::class.java))return
        prefs(c).edit().putString("widget:$widgetId",id).commit();update(c,widgetId)
    }
}
class IconWidgetProvider: AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) { for(id in ids) WidgetIcons.update(context,id) }
    override fun onDeleted(context: Context, ids: IntArray) { val e=WidgetIcons.prefs(context).edit();for(id in ids)e.remove("widget:$id");e.apply() }
}
class WidgetPinReceiver: BroadcastReceiver() {
    override fun onReceive(context: Context,intent: Intent) {
        val id=intent.getStringExtra("design_id") ?: return
        WidgetIcons.bind(context,intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,AppWidgetManager.INVALID_APPWIDGET_ID),id)
    }
}
class WidgetConfigActivity: Activity() {
    override fun onCreate(state: Bundle?) {
        super.onCreate(state);setResult(RESULT_CANCELED)
        val widgetId=intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,AppWidgetManager.INVALID_APPWIDGET_ID)
        if(widgetId==AppWidgetManager.INVALID_APPWIDGET_ID){finish();return}
        val root=LinearLayout(this).apply { orientation=LinearLayout.VERTICAL;setPadding(32,48,32,24) }
        root.addView(TextView(this).apply { text="Choisir une icône sans badge";textSize=24f;setPadding(0,0,0,24) })
        val entries=WidgetIcons.prefs(this).all.keys.filter { it.startsWith("design:") }.mapNotNull { key->
            val id=key.removePrefix("design:");WidgetIcons.design(this,id)?.let { Pair(id,it) }
        }
        if(entries.isEmpty()) root.addView(TextView(this).apply { text="Dans Icon Studio, ouvrez votre création, appuyez sur Appliquer puis choisissez Sans badge. Revenez ensuite ajouter ce widget.";textSize=17f })
        val list=ListView(this)
        list.adapter=ArrayAdapter(this,android.R.layout.simple_list_item_1,entries.map { it.second.optString("name") })
        list.setOnItemClickListener { _,_,position,_-> WidgetIcons.bind(this,widgetId,entries[position].first)
            setResult(RESULT_OK,Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,widgetId));finish() }
        root.addView(list,LinearLayout.LayoutParams(-1,0,1f));setContentView(root)
    }
}
