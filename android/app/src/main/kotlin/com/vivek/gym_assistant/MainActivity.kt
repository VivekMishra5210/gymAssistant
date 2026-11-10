package com.vivek.gym_assistant

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Backup channel: Android's own file picker (Downloads, Drive, …), no extra packages.
class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var localPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gym/backup")
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")
                when (call.method) {
                    // Save the file at `path` wherever the user picks.
                    "export" -> pick(result, path!!, EXPORT,
                        Intent(Intent.ACTION_CREATE_DOCUMENT)
                            .addCategory(Intent.CATEGORY_OPENABLE)
                            .setType("application/octet-stream")
                            .putExtra(Intent.EXTRA_TITLE, call.argument<String>("name")))
                    // Copy a file the user picks to `path`.
                    "import" -> pick(result, path!!, IMPORT,
                        Intent(Intent.ACTION_OPEN_DOCUMENT)
                            .addCategory(Intent.CATEGORY_OPENABLE)
                            .setType("*/*"))
                    // Fresh process, so the restored database is opened from scratch.
                    "restart" -> {
                        startActivity(packageManager.getLaunchIntentForPackage(packageName)!!
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK))
                        Runtime.getRuntime().exit(0)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun pick(result: MethodChannel.Result, path: String, code: Int, intent: Intent) {
        if (pending != null) return result.error("busy", "A picker is already open", null)
        pending = result
        localPath = path
        @Suppress("DEPRECATION") // FlutterActivity isn't a ComponentActivity
        startActivityForResult(intent, code)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != EXPORT && requestCode != IMPORT) return
        val result = pending ?: return
        pending = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) return result.success(false)
        // shortcut: copies on the main thread; fine for a DB of a few MB, move to a thread if it grows.
        try {
            val local = File(localPath!!)
            if (requestCode == EXPORT) {
                contentResolver.openOutputStream(uri, "wt")!!.use { out ->
                    local.inputStream().use { it.copyTo(out) }
                }
            } else {
                contentResolver.openInputStream(uri)!!.use { input ->
                    local.outputStream().use { input.copyTo(it) }
                }
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("io", e.message, null)
        }
    }

    private companion object {
        const val EXPORT = 4101
        const val IMPORT = 4102
    }
}
