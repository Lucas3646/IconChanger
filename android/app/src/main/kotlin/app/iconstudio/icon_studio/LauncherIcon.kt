package app.iconstudio.icon_studio

import android.graphics.*
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.Icon
import kotlin.math.*

/** Adaptive bitmap: full-bleed background, foreground contained in the 66/108 safe circle. */
object LauncherIcon {
    fun render(source: Bitmap, maxWidth: Int, maxHeight: Int, background: Int,
               background2: Int = background, gradient: Boolean = false, angle: Double = 0.0): Bitmap {
        // ShortcutManager reports the visible size, without the adaptive overscan.
        val visible = min(maxWidth, maxHeight).coerceIn(48, 512)
        val side = ceil(visible * (1 + 2 * AdaptiveIconDrawable.getExtraInsetFraction())).toInt()
        val output = Bitmap.createBitmap(side, side, Bitmap.Config.ARGB_8888)
        output.density = Bitmap.DENSITY_NONE
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        if (gradient) {
            val a = angle * PI * 2
            val half = side / 2f
            paint.shader = LinearGradient(
                half - cos(a).toFloat() * half, half - sin(a).toFloat() * half,
                half + cos(a).toFloat() * half, half + sin(a).toFloat() * half,
                background, background2, Shader.TileMode.CLAMP)
        } else paint.color = background
        canvas.drawRect(0f, 0f, side.toFloat(), side.toFloat(), paint)
        paint.shader = null
        val pixels = IntArray(source.width * source.height)
        source.getPixels(pixels, 0, source.width, 0, 0, source.width, source.height)
        var left = source.width; var top = source.height; var right = -1; var bottom = -1
        for (y in 0 until source.height) for (x in 0 until source.width) {
            if (Color.alpha(pixels[y * source.width + x]) > 0) {
                left = min(left, x); right = max(right, x)
                top = min(top, y); bottom = max(bottom, y)
            }
        }
        if (right >= left && bottom >= top) {
            val width = right - left + 1f; val height = bottom - top + 1f
            // Fit the entire artwork rectangle in the safe circle, preserving aspect ratio.
            val scale = (side * 66f / 108f) / hypot(width, height)
            val target = RectF((side - width * scale) / 2, (side - height * scale) / 2,
                (side + width * scale) / 2, (side + height * scale) / 2)
            paint.color = Color.WHITE
            canvas.drawBitmap(source, Rect(left, top, right + 1, bottom + 1), target, paint)
        }
        return output
    }

    fun create(source: Bitmap, maxWidth: Int, maxHeight: Int, background: Int,
               background2: Int = background, gradient: Boolean = false, angle: Double = 0.0): Icon =
        Icon.createWithAdaptiveBitmap(render(source, maxWidth, maxHeight, background, background2, gradient, angle))
}
