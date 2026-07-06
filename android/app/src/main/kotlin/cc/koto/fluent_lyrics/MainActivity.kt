package cc.koto.fluent_lyrics

import android.content.ComponentName
import android.content.Context
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSession
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "cc.koto.fluent_lyrics/media"
    private val EVENTS_CHANNEL = "cc.koto.fluent_lyrics/media_events"
    private val mainHandler = Handler(Looper.getMainLooper())
    private var lastActiveSessionToken: MediaSession.Token? = null
    private var lastActivePackageName: String? = null
    private var eventSink: EventChannel.EventSink? = null
    private var activeSessionsListener: MediaSessionManager.OnActiveSessionsChangedListener? = null
    private val observedControllers = mutableMapOf<MediaSession.Token, MediaController>()
    private val controllerCallback = object : MediaController.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadata?) {
            emitCurrentStatus("metadata")
        }

        override fun onPlaybackStateChanged(state: PlaybackState?) {
            emitCurrentStatus("playbackState")
        }

        override fun onSessionDestroyed() {
            updateObservedControllers()
            emitCurrentStatus("sessionDestroyed")
        }
    }

    // Cache the most recent artwork data-URL.  Without this, the 250 ms
    // poll re-runs Bitmap.compress(JPEG) on the same album art ~4× per
    // second, spamming SkJpegEncoder logs and burning CPU on Skia encode.
    //
    // Key uses metadata identity (title|artist|album|duration) only —
    // bitmap.generationId is unreliable here because MediaSession may hand
    // back a fresh Bitmap instance on each read even when the pixels are
    // identical, defeating the cache entirely.  Bitmap dimensions are
    // included as a cheap secondary signal so a rare in-track artwork
    // resize (different resolution) still invalidates.
    private var cachedArtKey: String? = null
    private var cachedArtUrl: String? = null

    private fun buildArtCacheKey(metadata: MediaMetadata, art: Bitmap): String {
        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE) ?: ""
        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: ""
        val album = metadata.getString(MediaMetadata.METADATA_KEY_ALBUM) ?: ""
        val duration = metadata.getLong(MediaMetadata.METADATA_KEY_DURATION)
        return "$title|$artist|$album|$duration|${art.width}x${art.height}"
    }

    private fun encodeArtToDataUrl(metadata: MediaMetadata, art: Bitmap): String {
        val key = buildArtCacheKey(metadata, art)
        val cached = cachedArtUrl
        if (cached != null && cachedArtKey == key) {
            return cached
        }
        val stream = ByteArrayOutputStream()
        art.compress(Bitmap.CompressFormat.JPEG, 80, stream)
        val byteArray = stream.toByteArray()
        val base64String = Base64.encodeToString(byteArray, Base64.NO_WRAP)
        val dataUrl = "data:image/jpeg;base64,$base64String"
        cachedArtKey = key
        cachedArtUrl = dataUrl
        return dataUrl
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    ensureEventSubscriptions()
                    emitCurrentStatus()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    clearEventSubscriptions()
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStatus" -> {
                    ensureEventSubscriptions()
                    result.success(buildCurrentStatusMap())
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
                "seek" -> {
                    val position = call.argument<Number>("position")?.toLong()
                    if (position != null) {
                        val controller = getActiveController()
                        controller?.transportControls?.seekTo(position)
                        result.success(controller != null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Position is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun mediaSessionManager(): MediaSessionManager {
        return getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
    }

    private fun ensureEventSubscriptions() {
        if (eventSink == null || !isNotificationPermissionGranted()) {
            return
        }

        val manager = mediaSessionManager()
        if (activeSessionsListener == null) {
            val listener = MediaSessionManager.OnActiveSessionsChangedListener {
                updateObservedControllers()
                emitCurrentStatus("activeSessions")
            }
            activeSessionsListener = listener
            try {
                val componentName = ComponentName(this, MediaSessionListenerService::class.java)
                manager.addOnActiveSessionsChangedListener(listener, componentName, mainHandler)
            } catch (e: SecurityException) {
                activeSessionsListener = null
                return
            }
        }

        updateObservedControllers()
    }

    private fun clearEventSubscriptions() {
        activeSessionsListener?.let {
            try {
                mediaSessionManager().removeOnActiveSessionsChangedListener(it)
            } catch (_: SecurityException) {
                // Permission may have been revoked while the stream was active.
            }
        }
        activeSessionsListener = null
        observedControllers.values.forEach { it.unregisterCallback(controllerCallback) }
        observedControllers.clear()
    }

    private fun updateObservedControllers() {
        if (eventSink == null || !isNotificationPermissionGranted()) {
            clearObservedControllers()
            return
        }

        val componentName = ComponentName(this, MediaSessionListenerService::class.java)
        val sessions = try {
            mediaSessionManager().getActiveSessions(componentName)
        } catch (e: SecurityException) {
            clearObservedControllers()
            return
        }

        val nextTokens = sessions.map { it.sessionToken }.toSet()
        val removedTokens = observedControllers.keys - nextTokens
        removedTokens.forEach { token ->
            observedControllers.remove(token)?.unregisterCallback(controllerCallback)
        }

        sessions.forEach { controller ->
            if (!observedControllers.containsKey(controller.sessionToken)) {
                controller.registerCallback(controllerCallback, mainHandler)
                observedControllers[controller.sessionToken] = controller
            }
        }
    }

    private fun clearObservedControllers() {
        observedControllers.values.forEach { it.unregisterCallback(controllerCallback) }
        observedControllers.clear()
    }

    private fun emitCurrentStatus(event: String? = null) {
        mainHandler.post {
            ensureEventSubscriptions()
            eventSink?.success(buildCurrentStatusMap(event))
        }
    }

    private fun buildCurrentStatusMap(event: String? = null): Map<String, Any?>? {
        if (!isNotificationPermissionGranted()) {
            return null
        }
        val controller = getActiveController() ?: return null
        return buildStatusMap(controller, event)
    }

    private fun buildStatusMap(controller: MediaController, event: String? = null): Map<String, Any?> {
        val metadata = controller.metadata
        val playbackState = controller.playbackState

        val statusMap = mutableMapOf<String, Any?>()
        if (event != null) {
            statusMap["event"] = event
        }

        if (metadata != null) {
            val metaMap = mutableMapOf<String, Any?>()
            metaMap["title"] = metadata.getString(MediaMetadata.METADATA_KEY_TITLE)
            metaMap["artist"] = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
            metaMap["album"] = metadata.getString(MediaMetadata.METADATA_KEY_ALBUM)
            metaMap["duration"] = metadata.getLong(MediaMetadata.METADATA_KEY_DURATION)

            var artUrl = "fallback"
            val art = metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
                ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_ART)
                ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON)

            if (art != null) {
                artUrl = encodeArtToDataUrl(metadata, art)
            } else {
                val artUri = metadata.getString(MediaMetadata.METADATA_KEY_ALBUM_ART_URI)
                    ?: metadata.getString(MediaMetadata.METADATA_KEY_ART_URI)
                    ?: metadata.getString(MediaMetadata.METADATA_KEY_DISPLAY_ICON_URI)
                if (artUri != null) {
                    artUrl = artUri
                }
            }

            metaMap["artUrl"] = artUrl
            statusMap["metadata"] = metaMap
        } else {
            statusMap["metadata"] = null
        }

        statusMap["isPlaying"] = playbackState?.state == PlaybackState.STATE_PLAYING
        statusMap["position"] = playbackState?.position ?: 0L

        val actions = playbackState?.actions ?: 0L
        val abilityMap = mutableMapOf<String, Boolean>()
        abilityMap["canPlayPause"] = (actions and PlaybackState.ACTION_PLAY_PAUSE) != 0L ||
            ((actions and PlaybackState.ACTION_PLAY) != 0L && (actions and PlaybackState.ACTION_PAUSE) != 0L)
        abilityMap["canGoNext"] = (actions and PlaybackState.ACTION_SKIP_TO_NEXT) != 0L
        abilityMap["canGoPrevious"] = (actions and PlaybackState.ACTION_SKIP_TO_PREVIOUS) != 0L
        abilityMap["canSeek"] = (actions and PlaybackState.ACTION_SEEK_TO) != 0L
        statusMap["controlAbility"] = abilityMap

        return statusMap
    }

    private fun getActiveController(): MediaController? {
        val manager = mediaSessionManager()
        val componentName = ComponentName(this, MediaSessionListenerService::class.java)
        return try {
            val sessions = manager.getActiveSessions(componentName)
            val playingController = sessions.find {
                it.playbackState?.state == PlaybackState.STATE_PLAYING
            }
            if (playingController != null) {
                lastActiveSessionToken = playingController.sessionToken
                lastActivePackageName = playingController.packageName
                return playingController
            }

            val previousToken = lastActiveSessionToken
            if (previousToken != null) {
                sessions.find { it.sessionToken == previousToken }?.let {
                    return it
                }
            }

            val previousPackageName = lastActivePackageName
            if (previousPackageName != null) {
                sessions.find { it.packageName == previousPackageName }?.let {
                    return it
                }
            }

            sessions.firstOrNull()
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
