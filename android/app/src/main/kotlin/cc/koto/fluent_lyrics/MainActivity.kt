package cc.koto.fluent_lyrics

import android.content.ComponentName
import android.content.Context
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.graphics.Bitmap
import android.provider.Settings
import android.util.Base64
import android.util.Size
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "cc.koto.fluent_lyrics/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMetadata" -> {
                    val controller = getActiveController()
                    if (controller != null) {
                        val metadata = controller.metadata
                        if (metadata != null) {
                            val data = mutableMapOf<String, Any?>()
                            data["title"] = metadata.getString(MediaMetadata.METADATA_KEY_TITLE)
                            data["artist"] = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
                            data["album"] = metadata.getString(MediaMetadata.METADATA_KEY_ALBUM)
                            data["duration"] = metadata.getLong(MediaMetadata.METADATA_KEY_DURATION)
                            
                            // MediaMetadata API is not reliable for art on Android.
                            // Return a magic string to trigger fallback logic in Dart.
                            data["artUrl"] = "fallback"
                            result.success(data)
                        } else {
                            result.success(null)
                        }
                    } else {
                        result.success(null)
                    }
                }
                "getPosition" -> {
                    val controller = getActiveController()
                    val position = controller?.playbackState?.position ?: 0L
                    result.success(position)
                }
                "isPlaying" -> {
                    val controller = getActiveController()
                    val isPlaying = controller?.playbackState?.state == PlaybackState.STATE_PLAYING
                    result.success(isPlaying)
                }
                "checkPermission" -> {
                    result.success(isNotificationPermissionGranted())
                }
                "openPermissionSettings" -> {
                    val intent = android.content.Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getActiveController(): MediaController? {
        val manager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
        val componentName = ComponentName(this, MediaSessionListenerService::class.java)
        return try {
            val sessions = manager.getActiveSessions(componentName)
            // find the one that is playing
            sessions.find { it.playbackState?.state == PlaybackState.STATE_PLAYING } ?: sessions.firstOrNull()
        } catch (e: SecurityException) {
            // This happens if notification access is not granted
            null
        }
    }

    private fun isNotificationPermissionGranted(): Boolean {
        val packageName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat != null && flat.contains(packageName)
    }
}
