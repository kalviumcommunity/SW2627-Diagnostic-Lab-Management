package com.labtrack.lab_track

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.net.Uri

class MainActivity : FlutterActivity() {
    private var pendingPdf: ByteArray? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "labtrack/pdf")
            .setMethodCallHandler { call, result ->
                if (call.method != "savePdf") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val name = call.argument<String>("fileName")?.replace(Regex("[^A-Za-z0-9_.-]"), "_")
                if (bytes == null || bytes.isEmpty() || name.isNullOrBlank()) {
                    result.error("INVALID_PDF", "Missing PDF bytes or filename", null)
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    if (pendingResult != null) {
                        result.error("BUSY", "A PDF save is already in progress", null)
                        return@setMethodCallHandler
                    }
                    pendingPdf = bytes
                    pendingResult = result
                    startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/pdf"
                        putExtra(Intent.EXTRA_TITLE, name)
                    }, 7001)
                    return@setMethodCallHandler
                }
                var uri: Uri? = null
                try {
                    val values = ContentValues().apply {
                        put(MediaStore.Downloads.DISPLAY_NAME, name)
                        put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                        put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/LabTrack")
                        put(MediaStore.Downloads.IS_PENDING, 1)
                    }
                    val saved = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                        ?: error("Cannot create PDF in Downloads")
                    uri = saved
                    contentResolver.openOutputStream(saved)?.use { it.write(bytes) }
                        ?: error("Cannot write PDF")
                    values.clear()
                    values.put(MediaStore.Downloads.IS_PENDING, 0)
                    contentResolver.update(saved, values, null, null)
                    openPdf(saved)
                    result.success("Saved to Downloads/LabTrack/$name")
                } catch (e: Exception) {
                    uri?.let { contentResolver.delete(it, null, null) }
                    result.error("PDF_SAVE_FAILED", e.message, null)
                }
            }
    }

    private fun openPdf(uri: Uri) {
        try {
            startActivity(Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/pdf")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            })
        } catch (_: android.content.ActivityNotFoundException) {
            // The document is saved even if no PDF viewer is installed.
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 7001) return
        val result = pendingResult ?: return
        val bytes = pendingPdf
        pendingResult = null
        pendingPdf = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null || bytes == null) {
            result.error("CANCELLED", "PDF save cancelled", null)
            return
        }
        try {
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: error("Cannot write PDF")
            openPdf(uri)
            result.success("Saved PDF: $uri")
        } catch (e: Exception) {
            result.error("PDF_SAVE_FAILED", e.message, null)
        }
    }
}
