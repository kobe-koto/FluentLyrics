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
                "getStatus" -> {
                    if (!isNotificationPermissionGranted()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    val controller = getActiveController()
                    if (controller == null) {
                        result.success(null)
                        return@setMethodCallHandler
                    }

                    val metadata = controller.metadata
                    val playbackState = controller.playbackState

                    val statusMap = mutableMapOf<String, Any?>()

                    // Metadata
                    if (metadata != null) {
                        val metaMap = mutableMapOf<String, Any?>()
                        metaMap["title"] = metadata.getString(MediaMetadata.METADATA_KEY_TITLE)
                        metaMap["artist"] = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
                        metaMap["album"] = metadata.getString(MediaMetadata.METADATA_KEY_ALBUM)
                        metaMap["duration"] = metadata.getLong(MediaMetadata.METADATA_KEY_DURATION)
                        metaMap["artUrl"] = "fallback"
                        statusMap["metadata"] = metaMap
                    } else {
                        statusMap["metadata"] = null
                    }

                    // Playback State & Position
                    statusMap["isPlaying"] = playbackState?.state == PlaybackState.STATE_PLAYING
                    statusMap["position"] = playbackState?.position ?: 0L

                    // Control Ability
                    val actions = playbackState?.actions ?: 0L
                    val abilityMap = mutableMapOf<String, Boolean>()
                    abilityMap["canPlayPause"] = (actions and PlaybackState.ACTION_PLAY_PAUSE) != 0L ||
                                          ((actions and PlaybackState.ACTION_PLAY) != 0L && (actions and PlaybackState.ACTION_PAUSE) != 0L)
                    abilityMap["canGoNext"] = (actions and PlaybackState.ACTION_SKIP_TO_NEXT) != 0L
                    abilityMap["canGoPrevious"] = (actions and PlaybackState.ACTION_SKIP_TO_PREVIOUS) != 0L
                    statusMap["controlAbility"] = abilityMap

                    result.success(statusMap)
                }
                "checkPermission" -> {
                    result.success(isNotificationPermissionGranted())
                }
                "openPermissionSettings" -> {
                    val intent = android.content.Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "playPause" -> {
                    val controller = getActiveController()
                    if (controller != null) {
                        val state = controller.playbackState?.state
                        if (state == PlaybackState.STATE_PLAYING) {
                            controller.transportControls.pause()
                        } else {
                            controller.transportControls.play()
                        }
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "play" -> {
                    val controller = getActiveController()
                    controller?.transportControls?.play()
                    result.success(controller != null)
                }
                "pause" -> {
                    val controller = getActiveController()
                    controller?.transportControls?.pause()
                    result.success(controller != null)
                }
                "nextTrack" -> {
                    val controller = getActiveController()
                    controller?.transportControls?.skipToNext()
                    result.success(controller != null)
                }
                "previousTrack" -> {
                    val controller = getActiveController()
                    controller?.transportControls?.skipToPrevious()
                    result.success(controller != null)
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
        if (flat != null) {
            val names = flat.split(":")
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && cn.packageName == packageName) {
                    return true
                }
            }
        }
        return false
    }
}
