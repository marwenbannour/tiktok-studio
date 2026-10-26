package com.bannour.tiktok_studio

import android.os.SystemClock
import android.text.SpannableString
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.Presentation
import androidx.media3.effect.StaticOverlaySettings
import androidx.media3.effect.TextOverlay
import androidx.media3.effect.TextureOverlay
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import com.google.common.collect.ImmutableList
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// محرّك الفيديو (Lot 2): export عبر Jetpack Media3 Transformer.
///  - export()            : input واحد + نصّ static (prototype/test).
///  - exportComposition() : دمج عدّة clips + نصوص/ترجمة موقّتة (V21).
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
                    "exportComposition" -> exportComposition(
                        call.argument("clips")!!,
                        call.argument("overlays") ?: emptyList(),
                        call.argument("output")!!,
                        call.argument("width") ?: 1080,
                        call.argument("height") ?: 1920,
                        result)
                    else -> result.notImplemented()
                }
            }
    }

    /// نصّ موقّت: يبان برك خلال النوافذ [events] (بالـµs نسبةً للـclip).
    @OptIn(UnstableApi::class)
    private class TimedTextOverlay(
        private val events: List<Triple<String, Long, Long>>, // text, startUs, endUs
        private val anchorY: Float, // -1 تحت .. +1 فوق
    ) : TextOverlay() {
        // covariant return: الأب يرجّع OverlaySettings (interface)، StaticOverlaySettings
        // نوعو الفرعي — نتفادو تسمية الـinterface لأنّها مش منحلّة فهالنسخة.
        private val settings: StaticOverlaySettings =
            StaticOverlaySettings.Builder().setBackgroundFrameAnchor(0f, anchorY).build()

        override fun getText(presentationTimeUs: Long): SpannableString {
            for (e in events) {
                if (presentationTimeUs >= e.second && presentationTimeUs < e.third) {
                    return SpannableString(e.first)
                }
            }
            return SpannableString(" ") // فارغ = ما يبان شيء
        }

        override fun getOverlaySettings(presentationTimeUs: Long): StaticOverlaySettings = settings
    }

    @Suppress("UNCHECKED_CAST")
    @OptIn(UnstableApi::class)
    private fun exportComposition(
        clips: List<Map<String, Any>>,
        overlays: List<Map<String, Any>>,
        output: String,
        width: Int, height: Int,
        result: MethodChannel.Result,
    ) {
        try {
            if (clips.isEmpty()) {
                result.error("no_clips", "ماكانش clips فيديو للـexport.", null); return
            }
            val seqBuilder = EditedMediaItemSequence.Builder()
            for (clip in clips) {
                val path = clip["path"] as String
                val inMs = (clip["inMs"] as Number).toLong()
                val outMs = (clip["outMs"] as Number).toLong()
                val gStart = (clip["startMs"] as Number).toLong()
                val gEnd = gStart + (outMs - inMs)

                val mediaItem = MediaItem.Builder()
                    .setUri(path)
                    .setClippingConfiguration(
                        MediaItem.ClippingConfiguration.Builder()
                            .setStartPositionMs(inMs)
                            .setEndPositionMs(outMs)
                            .build())
                    .build()

                val effectsList = ArrayList<androidx.media3.common.Effect>()
                effectsList.add(Presentation.createForWidthAndHeight(
                    width, height, Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP))

                // نحوّلو النصوص للتوقيت النسبي متاع هذا الـclip (تقاطع مع نافذتو)
                val subs = ArrayList<Triple<String, Long, Long>>()
                val texts = ArrayList<Triple<String, Long, Long>>()
                for (ov in overlays) {
                    val s = (ov["startMs"] as Number).toLong()
                    val e = (ov["endMs"] as Number).toLong()
                    if (e <= gStart || s >= gEnd) continue // ما يتقاطعش مع الـclip
                    val relStartUs = (maxOf(s, gStart) - gStart) * 1000
                    val relEndUs = (minOf(e, gEnd) - gStart) * 1000
                    val txt = (ov["text"] as? String) ?: ""
                    if (txt.isBlank()) continue
                    val triple = Triple(txt, relStartUs, relEndUs)
                    if ((ov["kind"] as? String) == "text") texts.add(triple) else subs.add(triple)
                }
                val overlayList = ArrayList<TextureOverlay>()
                if (subs.isNotEmpty()) overlayList.add(TimedTextOverlay(subs, -0.8f))
                if (texts.isNotEmpty()) overlayList.add(TimedTextOverlay(texts, 0.8f))
                if (overlayList.isNotEmpty()) {
                    effectsList.add(OverlayEffect(ImmutableList.copyOf(overlayList)))
                }

                seqBuilder.addItem(EditedMediaItem.Builder(mediaItem)
                    .setEffects(Effects(emptyList(), effectsList))
                    .build())
            }

            val composition = Composition.Builder(seqBuilder.build()).build()
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
            transformer.start(composition, output)
        } catch (e: Exception) {
            result.error("export_exception", e.message, null)
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
