package kz.black13.kazwall_native

import android.app.Activity
import android.app.WallpaperManager
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

/** Отдельный класс, чтобы не пересечься с FileProvider других плагинов */
class ShareFileProvider : FileProvider()

class KazwallNativePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "kazwall_native")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isLockScreenSupported" -> result.success(isLockScreenSupported())
            "setWallpaper" -> background(result) {
                setWallpaper(call.argument<String>("path")!!, call.argument<Int>("target") ?: TARGET_BOTH)
            }
            "toJpeg" -> background(result) {
                toJpeg(
                    call.argument<String>("source")!!, call.argument<String>("target")!!,
                    call.argument<Int>("quality") ?: 92
                )
            }
            "shareImage" -> background(result) {
                shareImage(
                    call.argument<String>("path")!!, call.argument<String>("text") ?: "",
                    call.argument<String>("title") ?: "", call.argument<Boolean>("whatsApp") == true
                )
            }
            "openUrl" -> result.success(open(Intent(Intent.ACTION_VIEW, Uri.parse(call.argument<String>("url")))))
            "openStore" -> {
                val id = context.packageName
                result.success(
                    open(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$id"))) ||
                        open(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$id")))
                )
            }
            else -> result.notImplemented()
        }
    }

    // Работа с файлами и обоями идёт не в главном потоке
    private fun background(result: Result, work: () -> Boolean) {
        executor.execute {
            val done = try {
                work()
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
            main.post { result.success(done) }
        }
    }

    private fun isLockScreenSupported(): Boolean {
        return Build.VERSION.SDK_INT >= 24 && WallpaperManager.getInstance(context).isSetWallpaperAllowed
    }

    private fun setWallpaper(path: String, target: Int): Boolean {
        val bitmap = BitmapFactory.decodeFile(path) ?: return false
        val manager = WallpaperManager.getInstance(context)
        if (Build.VERSION.SDK_INT >= 24) {
            val flags = when (target) {
                TARGET_HOME -> WallpaperManager.FLAG_SYSTEM
                TARGET_LOCK -> WallpaperManager.FLAG_LOCK
                else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
            }
            manager.setBitmap(bitmap, null, true, flags)
        } else {
            manager.setBitmap(bitmap)
        }
        return true
    }

    private fun toJpeg(source: String, target: String, quality: Int): Boolean {
        val bitmap = BitmapFactory.decodeFile(source) ?: return false
        FileOutputStream(target).use { bitmap.compress(Bitmap.CompressFormat.JPEG, quality, it) }
        return true
    }

    private fun shareImage(path: String, text: String, title: String, whatsApp: Boolean): Boolean {
        val source = File(path)
        val png = path.endsWith(".png", true)
        // FileProvider отдаёт другим приложениям только файлы из cache/shared
        val dir = File(context.cacheDir, "shared")
        dir.mkdirs()
        val target = File(dir, "kazakhstan." + if (png) "png" else "jpg")
        if (source.canonicalPath != target.canonicalPath) source.copyTo(target, true)

        val uri = FileProvider.getUriForFile(context, context.packageName + ".kazwall.fileprovider", target)
        val intent = Intent(Intent.ACTION_SEND)
        intent.type = if (png) "image/png" else "image/jpeg"
        intent.putExtra(Intent.EXTRA_STREAM, uri)
        intent.putExtra(Intent.EXTRA_TEXT, text)
        intent.clipData = ClipData.newRawUri(null, uri)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

        // WhatsApp не установлен — показываем обычное окно выбора
        if (whatsApp && open(Intent(intent).setPackage("com.whatsapp"))) return true
        return open(Intent.createChooser(intent, title))
    }

    private fun open(intent: Intent): Boolean {
        return try {
            val from = activity
            if (from != null) {
                from.startActivity(intent)
            } else {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            }
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    companion object {
        const val TARGET_HOME = 0
        const val TARGET_LOCK = 1
        const val TARGET_BOTH = 2
    }
}
