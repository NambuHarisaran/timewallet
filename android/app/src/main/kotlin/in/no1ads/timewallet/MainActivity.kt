package `in`.no1ads.timewallet

import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Hand-rolled share channel: share_plus can't be added to this project
        // (new packages are blocked by a Defender/DDC file-lock), so the app
        // writes the PNG to the cache dir and fires ACTION_SEND itself.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "timewallet/share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareImage" -> {
                        try {
                            val bytes = call.argument<ByteArray>("bytes")
                                ?: throw IllegalArgumentException("bytes missing")
                            val caption = call.argument<String>("caption") ?: ""
                            val dir = File(cacheDir, "shares").apply { mkdirs() }
                            val file = File(dir, "timewallet-card.png")
                            file.writeBytes(bytes)
                            val uri = FileProvider.getUriForFile(
                                this, "$packageName.fileprovider", file)
                            val send = Intent(Intent.ACTION_SEND).apply {
                                type = "image/png"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                // ClipData makes the system sheet render the
                                // image preview thumbnail (Android 10+).
                                clipData = ClipData.newRawUri("card", uri)
                                if (caption.isNotEmpty()) {
                                    putExtra(Intent.EXTRA_TEXT, caption)
                                }
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(send, "Share card"))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SHARE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
