package com.github.gbandszxc.fl_pokedex

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 更新包安装通道（Dart 侧 lib/core/update/update_installer.dart）。
 *
 * 应用自身不下载、不写包，只把已下载的 APK 以 FileProvider content:// 交给
 * 系统包安装器（ACTION_VIEW），把「安装」这一步委托给 OS——与离线守卫
 * （唯一放行更新通道）的边界一致。
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.github.gbandszxc.fl_pokedex/update_installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> installApk(call.argument<String>("path"), result)
                    "openInstallPermissionSettings" ->
                        result.success(openInstallPermissionSettings())
                    else -> result.notImplemented()
                }
            }
    }

    private fun installApk(path: String?, result: MethodChannel.Result) {
        if (path.isNullOrBlank()) {
            result.success("invalid_path")
            return
        }
        val file = File(path)
        if (!file.exists()) {
            result.success("file_missing")
            return
        }
        // Android 8.0+：未授予「安装未知应用」时先让上层引导用户去系统设置。
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            result.success("permission_required")
            return
        }
        try {
            val uri: Uri = FileProvider.getUriForFile(
                this,
                "$packageName.update_installer",
                file,
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success("started")
        } catch (t: Throwable) {
            result.error("install_failed", t.message, null)
        }
    }

    private fun openInstallPermissionSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return false
        }
        return try {
            startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                    .setData(Uri.parse("package:$packageName"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            true
        } catch (t: Throwable) {
            false
        }
    }
}
