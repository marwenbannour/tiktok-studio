package com.bannour.tiktok_studio

import android.os.SystemClock
import android.text.SpannableString
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.Presentation
import androidx.media3.effect.TextOverlay
import androidx.media3.effect.TextureOverlay
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import com.google.common.collect.ImmutableList
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// محرّك الفيديو (Lot 2): export عبر Jetpack Media3 Transformer.
/// prototype: يستورد فيديو، يكتب نصّ عليه، export MP4 1080p، ويقيس المدّة.
class MainActivity : FlutterActivity() {
    private val channelName = "studio/video_engine"

    @OptIn(UnstableApi::class)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "export" -> export(call.argument("input")!!, call.argument("output")!!,
                        call.argument("text") ?: "", call.argument("width") ?: 1080,
                        call.argument("height") ?: 1920, result)
                    else -> result.notImplemented()
                }
            }
    }

    @OptIn(UnstableApi::class)
    private fun export(
        input: String, output: String, text: String,
        width: Int, height: Int, result: MethodChannel.Result,
    ) {
        try {
            val effectsList = ArrayList<androidx.media3.common.Effect>()
            effectsList.add(Presentation.createForWidthAndHeight(
                width, height, Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP))
            if (text.isNotBlank()) {
                val overlay: TextureOverlay =
                    TextOverlay.createStaticTextOverlay(SpannableString(text))
                effectsList.add(OverlayEffect(ImmutableList.of(overlay)))
            }
            val edited = EditedMediaItem.Builder(MediaItem.fromUri(input))
                .setEffects(Effects(emptyList(), effectsList))
                .build()

            val started = SystemClock.elapsedRealtime()
            var replied = false
            val transformer = Transformer.Builder(this)
                .addListener(object : Transformer.Listener {
                    override fun onCompleted(composition: Composition, r: ExportResult) {
                        if (replied) return; replied = true
                        result.success(mapOf(
                            "ms" to (SystemClock.elapsedRealtime() - started),
                            "output" to output,
                        ))
                    }

                    override fun onError(c: Composition, r: ExportResult, e: ExportException) {
                        if (replied) return; replied = true
                        result.error("export_failed", e.message, null)
                    }
                })
                .build()
            transformer.start(edited, output)
        } catch (e: Exception) {
            result.error("export_exception", e.message, null)
        }
    }
}
