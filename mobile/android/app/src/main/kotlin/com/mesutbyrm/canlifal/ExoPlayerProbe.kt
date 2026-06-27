package com.mesutbyrm.canlifal

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer

/**
 * just_audio altındaki ExoPlayer ile URL'yi doğrudan dener.
 * Flutter [MusicPipeline] loglarına sonuç döner.
 */
object ExoPlayerProbe {
    fun probe(
        context: Context,
        url: String,
        timeoutMs: Long = 12_000,
        callback: (Map<String, Any?>) -> Unit,
    ) {
        val handler = Handler(Looper.getMainLooper())
        var finished = false

        fun finish(result: Map<String, Any?>) {
            if (finished) return
            finished = true
            callback(result)
        }

        handler.post {
            val player = ExoPlayer.Builder(context).build()
            val listener = object : Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) {
                    if (playbackState == Player.STATE_READY) {
                        player.removeListener(this)
                        player.release()
                        finish(mapOf("ok" to true))
                    }
                }

                override fun onPlayerError(error: PlaybackException) {
                    player.removeListener(this)
                    player.release()
                    finish(
                        mapOf(
                            "ok" to false,
                            "errorCode" to error.errorCodeName,
                            "error" to (error.message ?: error.toString()),
                        ),
                    )
                }
            }
            player.addListener(listener)
            try {
                player.setMediaItem(MediaItem.fromUri(url))
                player.prepare()
            } catch (e: Exception) {
                player.removeListener(listener)
                player.release()
                finish(
                    mapOf(
                        "ok" to false,
                        "error" to (e.message ?: e.toString()),
                    ),
                )
                return@post
            }
            handler.postDelayed({
                if (!finished) {
                    player.removeListener(listener)
                    player.release()
                    finish(
                        mapOf(
                            "ok" to false,
                            "error" to "probe_timeout_${timeoutMs}ms",
                        ),
                    )
                }
            }, timeoutMs)
        }
    }
}
