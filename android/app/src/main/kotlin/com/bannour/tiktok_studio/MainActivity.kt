package com.bannour.tiktok_studio

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.media.MediaMetadataRetriever
import java.io.File
import android.graphics.Typeface
import android.os.SystemClock
import android.text.Layout
import android.text.SpannableString
import android.text.Spanned
import android.text.style.AbsoluteSizeSpan
import android.text.style.AlignmentSpan
import android.text.style.BackgroundColorSpan
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.audio.ChannelMixingAudioProcessor
import androidx.media3.common.audio.ChannelMixingMatrix
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
    private val reqPickAudio = 7001
    private var pendingPick: MethodChannel.Result? = null

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
                        call.argument("audio") ?: emptyList(),
                        call.argument("output")!!,
                        call.argument("width") ?: 1080,
                        call.argument("height") ?: 1920,
                        result)
                    "probeDuration" -> result.success(probeDuration(call.argument("path")!!))
                    "pickAudio" -> pickAudio(result)
                    else -> result.notImplemented()
                }
            }
    }

    /// مدّة ملف صوت/فيديو بالـms (MediaMetadataRetriever).
    private fun probeDuration(path: String): Long {
        val r = MediaMetadataRetriever()
        return try {
            r.setDataSource(path)
            r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
        } catch (_: Exception) {
            0L
        } finally {
            try { r.release() } catch (_: Exception) {}
        }
    }

    /// يفتح منتقي صوت النظام (SAF)، ينسخ المختار لملف مؤقّت، ويرجّع مسارو.
    /// (نتفادو file_picker — يتعارض مع win32 متاع share_plus/secure_storage.)
    private fun pickAudio(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "اختيار صوت جاري", null); return
        }
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
        }
        try {
            startActivityForResult(intent, reqPickAudio)
        } catch (e: Exception) {
            pendingPick = null
            result.error("no_picker", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != reqPickAudio) return
        val res = pendingPick ?: return
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            res.success(null); return // ألغى المستعمل
        }
        try {
            val name = uri.lastPathSegment?.substringAfterLast('/') ?: "audio"
            val ext = contentResolver.getType(uri)?.substringAfterLast('/')?.let { ".$it" } ?: ".m4a"
            val dest = File(cacheDir, "pick_${System.currentTimeMillis()}_$name$ext")
            contentResolver.openInputStream(uri)!!.use { input ->
                dest.outputStream().use { out -> input.copyTo(out) }
            }
            res.success(dest.absolutePath)
        } catch (e: Exception) {
            res.error("copy_failed", e.message, null)
        }
    }

    /// حدث نصّ موقّت مع التنسيق الجاهز (span).
    private class TextEvent(val span: SpannableString, val startUs: Long, val endUs: Long)

    /// نصّ موقّت: يبان برك خلال نافذتو، مع التنسيق (لون/حجم/bold/محاذاة/خلفية).
    @OptIn(UnstableApi::class)
    private class TimedTextOverlay(
        private val events: List<TextEvent>,
        private val anchorY: Float, // -1 تحت .. +1 فوق
    ) : TextOverlay() {
        private val empty = SpannableString(" ")
        // covariant return: الأب يرجّع OverlaySettings (interface)، StaticOverlaySettings
        // نوعو الفرعي — نتفادو تسمية الـinterface لأنّها مش منحلّة فهالنسخة.
        private val settings: StaticOverlaySettings =
            StaticOverlaySettings.Builder().setBackgroundFrameAnchor(0f, anchorY).build()

        override fun getText(presentationTimeUs: Long): SpannableString {
            for (e in events) {
                if (presentationTimeUs >= e.startUs && presentationTimeUs < e.endUs) return e.span
            }
            return empty // فارغ = ما يبان شيء
        }

        override fun getOverlaySettings(presentationTimeUs: Long): StaticOverlaySettings = settings
    }

    /// يبني SpannableString منسّق من خريطة overlay (مع قيم افتراضية آمنة).
    private fun styledSpan(ov: Map<String, Any>, defaultColor: Int, defaultSize: Int): SpannableString {
        val txt = (ov["text"] as? String) ?: ""
        val s = SpannableString(txt)
        val n = txt.length
        if (n == 0) return s
        fun parse(c: Any?, fallback: Int): Int =
            try { if (c is String && c.isNotBlank()) Color.parseColor(c) else fallback }
            catch (_: Exception) { fallback }

        val color = parse(ov["color"], defaultColor)
        val size = (ov["size"] as? Number)?.toInt() ?: defaultSize
        val bold = (ov["bold"] as? Boolean) ?: true
        val align = (ov["align"] as? String) ?: "center"
        s.setSpan(ForegroundColorSpan(color), 0, n, Spanned.SPAN_INCLUSIVE_INCLUSIVE)
        s.setSpan(AbsoluteSizeSpan(size, false), 0, n, Spanned.SPAN_INCLUSIVE_INCLUSIVE) // px
        if (bold) s.setSpan(StyleSpan(Typeface.BOLD), 0, n, Spanned.SPAN_INCLUSIVE_INCLUSIVE)
        (ov["bg"] as? String)?.let { bg ->
            if (bg.isNotBlank()) s.setSpan(BackgroundColorSpan(parse(bg, Color.TRANSPARENT)), 0, n,
                Spanned.SPAN_INCLUSIVE_INCLUSIVE)
        }
        val a = when (align) {
            "right" -> Layout.Alignment.ALIGN_OPPOSITE
            "left" -> Layout.Alignment.ALIGN_NORMAL
            else -> Layout.Alignment.ALIGN_CENTER
        }
        s.setSpan(AlignmentSpan.Standard(a), 0, n, Spanned.SPAN_INCLUSIVE_INCLUSIVE)
        return s
    }

    /// يبني سلسلة صوت (voix off / موسيقى): كل clip فبلاصتو عبر gaps (سكوت)،
    /// بلا فيديو، مع تحجيم الصوت (volume) عبر ChannelMixingAudioProcessor.
    @OptIn(UnstableApi::class)
    private fun audioSequence(items: List<Map<String, Any>>): EditedMediaItemSequence? {
        if (items.isEmpty()) return null
        val sorted = items.sortedBy { (it["startMs"] as Number).toLong() }
        val b = EditedMediaItemSequence.Builder().experimentalSetForceAudioTrack(true)
        var cursor = 0L
        for (a in sorted) {
            val start = (a["startMs"] as Number).toLong()
            if (start > cursor) { b.addGap((start - cursor) * 1000); cursor = start }
            val inMs = (a["inMs"] as Number).toLong()
            val outMs = (a["outMs"] as Number).toLong()
            val mi = MediaItem.Builder()
                .setUri(a["path"] as String)
                .setClippingConfiguration(
                    MediaItem.ClippingConfiguration.Builder()
                        .setStartPositionMs(inMs)
                        .setEndPositionMs(outMs)
                        .build())
                .build()
            val vol = (a["volume"] as? Number)?.toFloat() ?: 1f
            val eb = EditedMediaItem.Builder(mi).setRemoveVideo(true)
            if (vol != 1f) {
                val proc = ChannelMixingAudioProcessor()
                proc.putChannelMixingMatrix(ChannelMixingMatrix.create(1, 1).scaleBy(vol))
                proc.putChannelMixingMatrix(ChannelMixingMatrix.create(2, 2).scaleBy(vol))
                eb.setEffects(Effects(listOf(proc), emptyList()))
            }
            b.addItem(eb.build())
            cursor += (outMs - inMs)
        }
        return b.build()
    }

    @Suppress("UNCHECKED_CAST")
    @OptIn(UnstableApi::class)
    private fun exportComposition(
        clips: List<Map<String, Any>>,
        overlays: List<Map<String, Any>>,
        audio: List<Map<String, Any>>,
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
                val subs = ArrayList<TextEvent>()
                val texts = ArrayList<TextEvent>()
                for (ov in overlays) {
                    val s = (ov["startMs"] as Number).toLong()
                    val e = (ov["endMs"] as Number).toLong()
                    if (e <= gStart || s >= gEnd) continue // ما يتقاطعش مع الـclip
                    val relStartUs = (maxOf(s, gStart) - gStart) * 1000
                    val relEndUs = (minOf(e, gEnd) - gStart) * 1000
                    val txt = (ov["text"] as? String) ?: ""
                    if (txt.isBlank()) continue
                    val isText = (ov["kind"] as? String) == "text"
                    // نصّ incrusté: أصفر كبير فوق؛ ترجمة: أبيض أصغر تحت
                    val span = styledSpan(ov,
                        if (isText) Color.parseColor("#FFEB3B") else Color.WHITE,
                        if (isText) 64 else 48)
                    val ev = TextEvent(span, relStartUs, relEndUs)
                    if (isText) texts.add(ev) else subs.add(ev)
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

            // سلاسل الصوت (voix off + موسيقى) تتمزج فوق الفيديو
            val sequences = ArrayList<EditedMediaItemSequence>()
            sequences.add(seqBuilder.build())
            audioSequence(audio.filter { (it["kind"] as? String) == "voice" })?.let { sequences.add(it) }
            audioSequence(audio.filter { (it["kind"] as? String) == "music" })?.let { sequences.add(it) }

            val composition = Composition.Builder(sequences).build()
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
