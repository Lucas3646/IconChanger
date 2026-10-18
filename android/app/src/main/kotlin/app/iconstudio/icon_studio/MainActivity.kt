package app.iconstudio.icon_studio

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ImageDecoder
import android.graphics.Color
import android.graphics.drawable.Icon
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors
import kotlin.math.*

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pickerResult: MethodChannel.Result? = null
    private var exportBytes: ByteArray? = null
    private val manager get() = getSystemService(ShortcutManager::class.java)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "iconstudio/android").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "openPrivacyPolicy" -> {
                        startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse("https://github.com/Lucas3646/IconChanger/blob/main/PRIVACY.md")))
                        result.success(null)
                    }
                    "storageDirectory" -> result.success(filesDir.absolutePath)
                    "listApps" -> worker.execute {
                        try {
                            val query = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                            val cache = File(filesDir, "app_icons").apply { mkdirs() }
                            val apps = packageManager.queryIntentActivities(query, 0)
                                .filter { it.activityInfo.packageName != packageName }
                                .distinctBy { it.activityInfo.packageName }
                                .map { info ->
                                    val pkg = info.activityInfo.packageName
                                    val file = File(cache, "$pkg.png")
                                    val updated = packageManager.getPackageInfo(pkg, 0).lastUpdateTime
                                    if (!file.exists() || file.lastModified() < updated) {
                                        val icon = info.loadIcon(packageManager)
                                        val bitmap = Bitmap.createBitmap(192, 192, Bitmap.Config.ARGB_8888)
                                        icon.setBounds(0, 0, 192, 192); icon.draw(Canvas(bitmap))
                                        file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
                                        bitmap.recycle()
                                    }
                                    mapOf("package" to pkg, "name" to info.loadLabel(packageManager).toString(),
                                        "icon" to file.absolutePath, "system" to ((info.activityInfo.applicationInfo.flags and 1) != 0))
                                }.sortedBy { (it["name"] as String).lowercase() }
                            main.post { result.success(apps) }
                        } catch (e: Exception) { main.post { result.error("APPS", "Impossible de lire les applications.", null) } }
                    }
                    "importImage" -> {
                        if (pickerResult != null) { result.error("BUSY", "Une sélection est déjà ouverte.", null); return@setMethodCallHandler }
                        pickerResult = result
                        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            type = "image/*"; addCategory(Intent.CATEGORY_OPENABLE)
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/png", "image/jpeg", "image/webp"))
                        }, 101)
                    }
                    "exportPng" -> {
                        if (pickerResult != null) { result.error("BUSY", "Une sélection est déjà ouverte.", null); return@setMethodCallHandler }
                        exportBytes = call.argument<ByteArray>("bytes") ?: throw IllegalArgumentException("Image absente")
                        pickerResult = result
                        startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            type = "image/png"; addCategory(Intent.CATEGORY_OPENABLE)
                            putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "icon-studio.png")
                        }, 102)
                    }
                    "shortcutSupport" -> result.success(manager.isRequestPinShortcutSupported)
                    "shortcutStates" -> {
                        val ids = manager.pinnedShortcuts.map { it.id }.toSet()
                        val prefs = getSharedPreferences("pins", Context.MODE_PRIVATE)
                        val states = prefs.all.filterKeys { it in ids }.mapValues { "pinned" }.toMutableMap()
                        for (id in ids) states[id] = "pinned"
                        result.success(states)
                    }
                    "pinShortcut" -> {
                        val id = call.argument<String>("id")!!
                        val pkg = call.argument<String>("package")!!
                        val name = call.argument<String>("name")?.trim().orEmpty().ifBlank {
                            packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
                        }
                        if (packageManager.getLaunchIntentForPackage(pkg) == null) {
                            result.error("MISSING_APP", "Cette application n’est plus installée.", null)
                        } else if (!manager.isRequestPinShortcutSupported) {
                            result.error("UNSUPPORTED", "Votre écran d’accueil ne permet pas l’ajout de raccourcis.", null)
                        } else {
                            val bytes = call.argument<ByteArray>("bytes")!!
                            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                                ?: throw IllegalArgumentException("Image invalide")
                            val intent = Intent(this, ShortcutLaunchActivity::class.java).apply {
                                action = Intent.ACTION_VIEW; putExtra("target_package", pkg)
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                            }
                            val shortcut = ShortcutInfo.Builder(this, id).setShortLabel(name.ifBlank { "Application" })
                                .setLongLabel(name.ifBlank { "Application" }).setIcon(LauncherIcon.create(
                                    bitmap, manager.iconMaxWidth, manager.iconMaxHeight,
                                    call.argument<Number>("background")?.toInt() ?: Color.BLACK,
                                    call.argument<Number>("background2")?.toInt() ?: Color.BLACK,
                                    call.argument<Boolean>("gradient") ?: false,
                                    call.argument<Number>("gradientAngle")?.toDouble() ?: 0.0
                                ))
                                .setIntent(intent).build()
                            if (manager.pinnedShortcuts.any { it.id == id }) {
                                if (manager.updateShortcuts(listOf(shortcut))) result.success("updated")
                                else result.error("RATE_LIMIT", "Android limite les mises à jour. Réessayez dans un instant.", null)
                            } else {
                                val callbackIntent = Intent(this, PinReceiver::class.java).apply {
                                    action = "app.iconstudio.PINNED.$id"; putExtra("shortcut_id", id)
                                }
                                val callback = PendingIntent.getBroadcast(this, id.hashCode(), callbackIntent,
                                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                                val accepted = manager.requestPinShortcut(shortcut, callback.intentSender)
                                result.success(if (accepted) "pending" else "unsupported")
                            }
                            bitmap.recycle()
                        }
                    }
                    "hasWidgetDesign" -> result.success(WidgetIcons.design(this,call.argument<String>("id")!!) != null)
                    "updateWidgetDesign" -> {
                        WidgetIcons.store(
                            this, call.argument<String>("id")!!, call.argument<String>("name")!!,
                            call.argument<String>("package")!!, call.argument<ByteArray>("bytes")!!,
                            call.argument<Number>("background")?.toInt() ?: Color.BLACK,
                            call.argument<Number>("background2")?.toInt() ?: Color.BLACK,
                            call.argument<Boolean>("gradient") ?: false,
                            call.argument<Number>("gradientAngle")?.toDouble() ?: 0.0
                        )
                        result.success(true)
                    }
                    "pinWidget" -> {
                        val id=call.argument<String>("id")!!
                        val pkg=call.argument<String>("package")!!
                        if(packageManager.getLaunchIntentForPackage(pkg)==null) { result.error("MISSING_APP","Application désinstallée.",null);return@setMethodCallHandler }
                        WidgetIcons.store(
                            this, id, call.argument<String>("name")!!, pkg,
                            call.argument<ByteArray>("bytes")!!,
                            call.argument<Number>("background")?.toInt() ?: Color.BLACK,
                            call.argument<Number>("background2")?.toInt() ?: Color.BLACK,
                            call.argument<Boolean>("gradient") ?: false,
                            call.argument<Number>("gradientAngle")?.toDouble() ?: 0.0
                        )
                        val wm=AppWidgetManager.getInstance(this)
                        if(!wm.isRequestPinAppWidgetSupported) result.success("manual")
                        else {
                            val callback=PendingIntent.getBroadcast(this,id.hashCode(),Intent(this,WidgetPinReceiver::class.java).setAction("app.iconstudio.WIDGET.$id").putExtra("design_id",id),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
                            val extras=Bundle().apply { putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW,WidgetIcons.views(this@MainActivity,id)) }
                            result.success(if(wm.requestPinAppWidget(ComponentName(this,IconWidgetProvider::class.java),extras,callback)) "pending" else "manual")
                        }
                    }
                    "launchApp" -> {
                        val pkg = call.argument<String>("package")!!
                        val intent = packageManager.getLaunchIntentForPackage(pkg)
                        if (intent == null) result.error("MISSING_APP", "Application désinstallée.", null)
                        else { startActivity(intent); result.success(true) }
                    }
                    "processImage" -> worker.execute {
                        try {
                            val path = call.argument<String>("path")!!
                            val mode = call.argument<String>("mode") ?: "original"
                            val tolerance = call.argument<Number>("tolerance")?.toDouble() ?: 0.25
                            val source = decodeBounded(path, 1024)
                            val w = source.width; val h = source.height
                            val pixels = IntArray(w * h); source.getPixels(pixels, 0, w, 0, 0, w, h)
                            fun brightness(c: Int)=(Color.red(c)*.299+Color.green(c)*.587+Color.blue(c)*.114)/255.0
                            var effective=mode
                            if(mode=="autoLogo") {
                                val border=mutableListOf<Int>()
                                for(y in 0 until h step 2) for(x in 0 until w step 2) {
                                    if(x<w*.05||x>w*.95||y<h*.05||y>h*.95) {
                                        val c=pixels[y*w+x];if(Color.alpha(c)>230)border.add(c)
                                    }
                                }
                                effective=when {
                                    border.size<4 -> "original"
                                    border.count { brightness(it)>.86 }>border.size*.85 -> "removeWhite"
                                    border.count { brightness(it)<.14 }>border.size*.85 -> "removeBlack"
                                    else -> "original"
                                }
                                if(effective=="original") { source.recycle();main.post { result.success(path) };return@execute }
                            }
                            val output=IntArray(pixels.size)
                            val opacity=DoubleArray(pixels.size) { Color.alpha(pixels[it])/255.0 }
                            val luminance=DoubleArray(pixels.size) { brightness(pixels[it])*opacity[it] }
                            fun sobel(values: DoubleArray,x: Int,y: Int): Double {
                                fun at(a: Int,b: Int)=values[b.coerceIn(0,h-1)*w+a.coerceIn(0,w-1)]
                                val gx=-at(x-1,y-1)+at(x+1,y-1)-2*at(x-1,y)+2*at(x+1,y)-at(x-1,y+1)+at(x+1,y+1)
                                val gy=-at(x-1,y-1)-2*at(x,y-1)-at(x+1,y-1)+at(x-1,y+1)+2*at(x,y+1)+at(x+1,y+1)
                                return sqrt(gx*gx+gy*gy)
                            }
                            for(y in 0 until h) for(x in 0 until w) {
                                val i=y*w+x;val c=pixels[i];val alpha=Color.alpha(c)
                                if(effective=="edges") {
                                    val gradient=max(sobel(luminance,x,y),sobel(opacity,x,y))
                                    val edge=((gradient-tolerance*.7)*2).coerceIn(0.0,1.0)
                                    output[i]=Color.argb((255*edge).toInt(),255,255,255)
                                } else {
                                    val light=brightness(c)
                                    val mask=if(effective=="removeWhite") ((1-light)/max(.03,tolerance)).coerceIn(0.0,1.0)
                                        else (light/max(.03,tolerance)).coerceIn(0.0,1.0)
                                    output[i]=Color.argb((alpha*mask).toInt(),Color.red(c),Color.green(c),Color.blue(c))
                                }
                            }
                            val resultBitmap = Bitmap.createBitmap(output,w,h,Bitmap.Config.ARGB_8888)
                            val file = File(File(filesDir,"images").apply { mkdirs() },"processed-${UUID.randomUUID()}.png")
                            file.outputStream().use { resultBitmap.compress(Bitmap.CompressFormat.PNG,100,it) }
                            source.recycle(); resultBitmap.recycle()
                            main.post { result.success(file.absolutePath) }
                        } catch(e: Exception) { main.post { result.error("IMAGE", "Impossible de transformer cette image.", null) } }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { result.error("ANDROID", e.localizedMessage ?: "Opération impossible.", null) }
        }
    }
    private fun decodeBounded(path: String, maxSize: Int): Bitmap {
        return ImageDecoder.decodeBitmap(ImageDecoder.createSource(File(path))) { decoder, info, _ ->
            decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
            val ratio = min(1.0, maxSize.toDouble() / max(info.size.width, info.size.height))
            decoder.setTargetSize(max(1, (info.size.width * ratio).toInt()), max(1, (info.size.height * ratio).toInt()))
        }

    }
    @Deprecated("Activity result bridge for Flutter")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode,resultCode,data)
        if (requestCode != 101 && requestCode != 102) return
        val result = pickerResult ?: return; pickerResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            exportBytes = null; result.success(null); return
        }
        val bytes = exportBytes; exportBytes = null
        worker.execute {
            try {
                if (requestCode == 101) {
                    val dir = File(filesDir,"images").apply { mkdirs() }
                    val temp = File(dir,"import-${UUID.randomUUID()}.tmp")
                    try {
                        contentResolver.openInputStream(uri)!!.use { input ->
                            temp.outputStream().use { out ->
                                val buffer = ByteArray(8192); var total = 0
                                while (true) { val read = input.read(buffer); if (read < 0) break
                                    total += read; if (total > 40*1024*1024) throw IllegalArgumentException("Image trop volumineuse (40 Mo maximum).")
                                    out.write(buffer,0,read)
                                }
                            }
                        }
                        val bitmap = decodeBounded(temp.absolutePath,2048)
                        val file = File(dir,"image-${UUID.randomUUID()}.png")
                        file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG,100,it) }; bitmap.recycle()
                        main.post { result.success(file.absolutePath) }
                    } finally { temp.delete() }
                } else {
                    contentResolver.openOutputStream(uri)!!.use { it.write(bytes!!) }
                    main.post { result.success(true) }
                }
            } catch (e: Exception) { main.post { result.error("FILE", e.localizedMessage ?: "Fichier inaccessible.",null) } }
        }
    }
}

class PinReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra("shortcut_id") ?: return
        context.getSharedPreferences("pins",Context.MODE_PRIVATE).edit().putBoolean(id,true).apply()
    }
}
class ShortcutLaunchActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val pkg = intent.getStringExtra("target_package")
        try {
            val launch = pkg?.let { packageManager.getLaunchIntentForPackage(it) }
            if (launch == null || pkg == packageName) Toast.makeText(this,"Cette application n’est plus disponible.",Toast.LENGTH_LONG).show()
            else startActivity(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (e: Exception) { Toast.makeText(this,"Impossible d’ouvrir cette application.",Toast.LENGTH_LONG).show() }
        finish()
    }
}
