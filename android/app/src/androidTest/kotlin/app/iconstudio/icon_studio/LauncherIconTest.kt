package app.iconstudio.icon_studio

import android.content.*
import android.content.pm.*
import android.graphics.*
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class LauncherIconTest {
    @Test fun artworkFitsSafeCircleWithoutStretching() {
        val source = Bitmap.createBitmap(400, 200, Bitmap.Config.ARGB_8888)
        source.eraseColor(Color.RED)
        val output = LauncherIcon.render(source, 192, 192, Color.BLACK)
        var count = 0
        var minX = output.width; var maxX = 0; var minY = output.height; var maxY = 0
        val radius = output.width * 66.0 / 108 / 2 + 1.5
        for (y in 0 until output.height) for (x in 0 until output.width) {
            if (Color.red(output.getPixel(x, y)) > 20) {
                count++
                minX = minOf(minX, x); maxX = maxOf(maxX, x)
                minY = minOf(minY, y); maxY = maxOf(maxY, y)
                assertTrue(Math.hypot(x + .5 - output.width / 2.0, y + .5 - output.height / 2.0) <= radius)
            }
        }
        assertTrue(count > 1000)
        assertEquals(2.0, (maxX-minX+1).toDouble()/(maxY-minY+1), .05)
        assertTrue(kotlin.math.abs(output.width-1-minX-maxX) <= 1)
        assertTrue(kotlin.math.abs(output.height-1-minY-maxY) <= 1)
        assertEquals(Color.BLACK, output.getPixel(0,0))
        source.recycle(); output.recycle()
    }

    @Test fun pinLabelAndLaunchOnLauncher() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val device = UiDevice.getInstance(instrumentation)
        val manager = context.getSystemService(ShortcutManager::class.java)
        assertTrue(manager.isRequestPinShortcutSupported)
        val source = Bitmap.createBitmap(256,256,Bitmap.Config.ARGB_8888)
        Canvas(source).drawCircle(128f,128f,100f,Paint().apply { color=Color.MAGENTA })
        val intent = Intent(context,ShortcutLaunchActivity::class.java)
            .setAction(Intent.ACTION_VIEW).putExtra("target_package","com.android.settings")
        val shortcut = ShortcutInfo.Builder(context,"launcher-regression")
            .setShortLabel("Instagram").setLongLabel("Instagram")
            .setIcon(LauncherIcon.create(source,manager.iconMaxWidth,manager.iconMaxHeight,Color.BLACK))
            .setIntent(intent).build()
        context.startActivity(Intent(context,MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        device.wait(Until.hasObject(By.pkg(context.packageName).depth(0)),15000)
        instrumentation.runOnMainSync { assertTrue(manager.requestPinShortcut(shortcut,null)) }
        val folder = File(context.getExternalFilesDir(null),"launcher-proof").apply { mkdirs() }
        device.waitForIdle()
        device.dumpWindowHierarchy(File(folder,"confirmation.xml"))
        device.takeScreenshot(File(folder,"confirmation.png"))
        val add = device.wait(Until.findObject(By.res("android", "button1")),15000)
        assertNotNull("Native launcher confirmation",add)
        add.click()
        device.pressHome()
        assertTrue(device.wait(Until.hasObject(By.text("Instagram")),15000))
        val label = device.findObject(By.text("Instagram"))
        val pinned = manager.pinnedShortcuts.single { it.id == "launcher-regression" }
        assertEquals("Instagram", pinned.shortLabel.toString())
        assertEquals("Instagram", pinned.longLabel.toString())
        device.takeScreenshot(File(folder,"home.png"))
        device.dumpWindowHierarchy(File(folder,"home.xml"))
        label.click()
        assertTrue("Target app opens",device.wait(Until.hasObject(By.pkg("com.android.settings").depth(0)),15000))
        device.pressHome()
    }
}
