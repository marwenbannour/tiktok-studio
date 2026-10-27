package com.bannour.tiktok_studio

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import android.graphics.Bitmap
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
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.ChannelMixingAudioProcessor
import androidx.media3.common.audio.ChannelMixingMatrix
import androidx.media3.common.audio.SonicAudioProcessor
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.Effect
import androidx.media3.effect.Contrast
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.GaussianBlur
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.Presentation
import androidx.media3.effect.RgbAdjustment
import androidx.media3.effect.RgbFilter
import androidx.media3.effect.SpeedChangeEffect
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

    // export جاري: باش نبعثو التقدّم لـFlutter وننجمو نلغيوه
    private var channel: MethodChannel? = null
    private var activeTransformer: Transformer? = null
    private var activeResult: MethodChannel.Result? = null
    private val progressHandler = Handler(Looper.getMainLooper())

    @OptIn(UnstableApi::class)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel!!.setMethodCallHandler { call, result ->
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
                    "probeInfo" -> result.success(probeInfo(call.argument("path")!!))
                    "pickAudio" -> pickAudio(result)
                    "cancelExport" -> { cancelExport(); result.success(null) }
                    "isAppInstalled" -> result.success(isAppInstalled(call.argument("package")!!))
                    "shareToApp" -> shareToApp(
                        call.argument("path")!!,
                        call.argument("package")!!,
                        call.argument("mime") ?: "video/mp4",
                        result)
                    else -> result.notImplemented()
                }
            }
    }

    // ---------------------------------------------------------------- CapCut

    /// التطبيق [pkg] منصّب؟ (يستحقّ <queries> في الـmanifest على Android 11+)
    private fun isAppInstalled(pkg: String): Boolean = try {
        if (Build.VERSION.SDK_INT >= 33) {
            packageManager.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(pkg, 0)
        }
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    /// يبعث ملف [path] لتطبيق [pkg] (ACTION_SEND + FileProvider).
    /// يرجّع false كان التطبيق موش منصّب ولا ما قبلش → Dart يطلّع menu المشاركة.
    /// الملف كان موش في dossier يخدمو الـprovider، يتنسخ في cache/capcut
    /// على thread آخر (فيديو كبير ما يجمّدش الـUI).
    private fun shareToApp(path: String, pkg: String, mime: String, result: MethodChannel.Result) {
        if (!isAppInstalled(pkg)) { result.success(false); return }
        val src = File(path)
        if (!src.exists()) { result.error("not_found", "الملف موش موجود", null); return }
        val main = Handler(Looper.getMainLooper())
        Thread {
            try {
                val uri = try {
                    FileProvider.getUriForFile(this, "$packageName.capcut_provider", src)
                } catch (_: IllegalArgumentException) {
                    val dir = File(cacheDir, "capcut").apply { mkdirs() }
                    val copy = File(dir, src.name)
                    src.copyTo(copy, overwrite = true)
                    FileProvider.getUriForFile(this, "$packageName.capcut_provider", copy)
                }
                main.post {
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = mime
                        setPackage(pkg)
                        putExtra(Intent.EXTRA_STREAM, uri)
                        clipData = ClipData.newRawUri("", uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (_: ActivityNotFoundException) {
                        result.success(false)
                    }
                }
            } catch (e: Exception) {
                main.post { result.error("share_failed", e.message, null) }
            }
        }.start()
    }

    // ---------------------------------------------------------- export state

    /// يبدا export: export واحد في نفس الوقت، ونبعثو التقدّم (0–100) كل 250 ms.
    @OptIn(UnstableApi::class)
    private fun startTracked(transformer: Transformer, result: MethodChannel.Result, start: () -> Unit) {
        if (activeTransformer != null) {
            result.error("busy", "فمّا export آخر جاري", null); return
        }
        activeTransformer = transformer
        activeResult = result
        try {
            start()
        } catch (e: Exception) {
            // الـcatch متاع المنادي يجاوب؛ إحنا نفرّغو الحالة برك
            activeTransformer = null
            activeResult = null
            throw e
        }
        val holder = androidx.media3.transformer.ProgressHolder()
        progressHandler.post(object : Runnable {
            override fun run() {
                val t = activeTransformer ?: return
                if (t.getProgress(holder) == Transformer.PROGRESS_STATE_AVAILABLE) {
                    channel?.invokeMethod("exportProgress", holder.progress)
                }
                progressHandler.postDelayed(this, 250)
            }
        })
    }

    /// يكمّل الـexport (نجاح ولا فشل): يرجّع النتيجة مرّة وحدة ويوقّف التقدّم.
    private fun finishTracked(reply: (MethodChannel.Result) -> Unit) {
        val r = activeResult ?: return
        activeResult = null
        activeTransformer = null
        progressHandler.removeCallbacksAndMessages(null)
        reply(r)
    }

    @OptIn(UnstableApi::class)
    private fun cancelExport() {
        val t = activeTransformer ?: return
        t.cancel() // Media3 ما ينادي حتى listener بعد cancel → نجاوبو إحنا
        finishTracked { it.error("cancelled", "تلغى الـexport", null) }
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

    /// معلومات ملف فيديو: أبعاد + مدّة + فمّا صوت/فيديو (للتحقّق end-to-end).
    private fun probeInfo(path: String): Map<String, Any> {
        val r = MediaMetadataRetriever()
        return try {
            r.setDataSource(path)
            fun meta(k: Int) = r.extractMetadata(k)
            mapOf(
                "width" to (meta(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0),
                "height" to (meta(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0),
                "durationMs" to (meta(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L),
                "rotation" to (meta(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0),
                "hasAudio" to (meta(MediaMetadataRetriever.METADATA_KEY_HAS_AUDIO) == "yes"),
                "hasVideo" to (meta(MediaMetadataRetriever.METADATA_KEY_HAS_VIDEO) == "yes"),
            )
        } catch (e: Exception) {
            mapOf("error" to (e.message ?: "probe failed"))
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

    /// V16: overlay كحلة full-frame بـalpha متغيّر → dip-to-black
    /// (fade-in من الكحلة فالبداية + fade-out للكحلة فالنهاية).
    @OptIn(UnstableApi::class)
    private class FadeBlackOverlay(
        private val bitmap: Bitmap,
        private val clipMs: Long,
        private val fadeMs: Long,
    ) : BitmapOverlay() {
        override fun getBitmap(presentationTimeUs: Long): Bitmap = bitmap

        override fun getOverlaySettings(presentationTimeUs: Long): StaticOverlaySettings {
            val ms = presentationTimeUs / 1000
            val a = when {
                ms < fadeMs -> 1f - ms.toFloat() / fadeMs // طالع من الكحلة
                ms > clipMs - fadeMs -> (ms - (clipMs - fadeMs)).toFloat() / fadeMs // نازل للكحلة
                else -> 0f
            }.coerceIn(0f, 1f)
            return StaticOverlaySettings.Builder().setAlphaScale(a).build()
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

    /// V10: span كاريوكي — نفس النصّ، الكلمة [hl] ملوّنة (accent) والباقي أبيض.
    private fun karaokeSpan(ov: Map<String, Any>, words: List<String>, hl: Int): SpannableString {
        val full = words.joinToString(" ")
        val s = SpannableString(full)
        val n = full.length
        if (n == 0) return s
        val base = try {
            val c = ov["color"]; if (c is String && c.isNotBlank()) Color.parseColor(c) else Color.WHITE
        } catch (_: Exception) { Color.WHITE }
        val accent = Color.parseColor("#00E5FF")
        val size = (ov["size"] as? Number)?.toInt() ?: 48
        val bold = (ov["bold"] as? Boolean) ?: true
        s.setSpan(AbsoluteSizeSpan(size, false), 0, n, Spanned.SPAN_INCLUSIVE_INCLUSIVE)
        if (bold) s.setSpan(StyleSpan(Typeface.BOLD), 0, n, Spanned.SPAN_INCLUSIVE_INCLUSIVE)
        s.setSpan(AlignmentSpan.Standard(Layout.Alignment.ALIGN_CENTER), 0, n,
            Spanned.SPAN_INCLUSIVE_INCLUSIVE)
        s.setSpan(ForegroundColorSpan(base), 0, n, Spanned.SPAN_INCLUSIVE_INCLUSIVE)
        var off = 0
        for (i in words.indices) {
            val len = words[i].length
            if (i == hl && len > 0) {
                s.setSpan(ForegroundColorSpan(accent), off, off + len,
                    Spanned.SPAN_INCLUSIVE_INCLUSIVE)
            }
            off += len + 1 // + مسافة
        }
        return s
    }

    /// V17: فلتر لوني → قائمة effects (RGB matrix). النصّ يتزاد بعدها فما يتأثّرش.
    @OptIn(UnstableApi::class)
    private fun filterEffects(name: String?): List<Effect> = when (name) {
        "bw" -> listOf(RgbFilter.createGrayscaleFilter())
        "warm" -> listOf(
            RgbAdjustment.Builder().setRedScale(1.18f).setBlueScale(0.85f).build())
        "cool" -> listOf(
            RgbAdjustment.Builder().setRedScale(0.85f).setBlueScale(1.18f).build())
        "cinematic" -> listOf(
            Contrast(0.25f),
            RgbAdjustment.Builder().setRedScale(1.08f).setGreenScale(0.98f)
                .setBlueScale(1.06f).build())
        else -> emptyList()
    }

    /// يبني سلسلة صوت (voix off / موسيقى): كل clip فبلاصتو عبر gaps (سكوت)،
    /// بلا فيديو، مع تحجيم الصوت (volume) عبر ChannelMixingAudioProcessor.
    /// صوت (voix off ولا موسيقى) → séquences. الـclips اللي يتقاطعو ما يتدفّوش
    /// لقدّام (كيما قبل): كل clip يتقاطع يمشي في séquence (lane) وحدو،
    /// والـComposition يمزجهم الكل في نفس الوقت → التوقيت يبقى مضبوط.
    @OptIn(UnstableApi::class)
    private fun audioSequences(items: List<Map<String, Any>>): List<EditedMediaItemSequence> {
        if (items.isEmpty()) return emptyList()
        class Lane(val builder: EditedMediaItemSequence.Builder, var cursor: Long)
        val lanes = ArrayList<Lane>()
        val sorted = items.sortedBy { (it["startMs"] as Number).toLong() }
        for (a in sorted) {
            val start = (a["startMs"] as Number).toLong()
            val inMs = (a["inMs"] as Number).toLong()
            val outMs = (a["outMs"] as Number).toLong()
            if (outMs <= inMs) continue
            val lane = lanes.firstOrNull { it.cursor <= start } ?: Lane(
                EditedMediaItemSequence.Builder().experimentalSetForceAudioTrack(true), 0L
            ).also { lanes.add(it) }
            if (start > lane.cursor) {
                lane.builder.addGap((start - lane.cursor) * 1000)
                lane.cursor = start
            }
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
            lane.builder.addItem(eb.build())
            lane.cursor += (outMs - inMs)
        }
        return lanes.map { it.builder.build() }
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
            var blackBitmap: Bitmap? = null // V16: يتعمل مرّة وحدة كان فمّا fade
            val seqBuilder = EditedMediaItemSequence.Builder()
            for (clip in clips) {
                val path = clip["path"] as String
                val inMs = (clip["inMs"] as Number).toLong()
                val outMs = (clip["outMs"] as Number).toLong()
                val gStart = (clip["startMs"] as Number).toLong()
                val speed = (clip["speed"] as? Number)?.toFloat() ?: 1f
                // المدّة على الـtimeline (بعد السرعة)؛ fallback لنافذة المصدر
                val timelineMs = (clip["timelineMs"] as? Number)?.toLong() ?: (outMs - inMs)
                val gEnd = gStart + timelineMs

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

                // V14: السرعة — فيديو عبر SpeedChangeEffect + صوت عبر SonicAudioProcessor
                val audioProcessors = ArrayList<AudioProcessor>()
                if (speed != 1f && speed > 0f) {
                    effectsList.add(SpeedChangeEffect(speed))
                    audioProcessors.add(SonicAudioProcessor().apply { setSpeed(speed) })
                }

                // V17: الفلتر اللوني (قبل النصّ باش النصّ ما يتفلترش)
                effectsList.addAll(filterEffects(clip["filter"] as? String))

                // V18: الطمس (Gaussian blur) — قبل النصّ باش النصّ يبقى واضح
                val blur = (clip["blur"] as? Number)?.toFloat() ?: 0f
                if (blur > 0f) effectsList.add(GaussianBlur(blur))

                // نحوّلو النصوص للتوقيت النسبي متاع هذا الـclip (تقاطع مع نافذتو)
                val subs = ArrayList<TextEvent>()
                val texts = ArrayList<TextEvent>()
                for (ov in overlays) {
                    val s = (ov["startMs"] as Number).toLong()
                    val e = (ov["endMs"] as Number).toLong()
                    if (e <= gStart || s >= gEnd) continue // ما يتقاطعش مع الـclip
                    val txt = (ov["text"] as? String) ?: ""
                    if (txt.isBlank()) continue
                    val isText = (ov["kind"] as? String) == "text"
                    val karaoke = ov["karaoke"] == true && !isText

                    if (karaoke) {
                        // V10: نقسّم النافذة على الكلمات، span لكل كلمة مع تمييزها
                        val words = txt.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
                        if (words.isNotEmpty()) {
                            // الوقت يتقسم حسب طول الكلمة (عدد الحروف)، موش بالتساوي:
                            // الكلمة الطويلة تاخو وقت أكثر كيما في النطق.
                            val weights = words.map { w -> maxOf(1, w.count { it.isLetterOrDigit() }) }
                            val total = weights.sum().toDouble()
                            var acc = 0
                            for (i in words.indices) {
                                val ws = s + ((e - s) * (acc / total)).toLong()
                                acc += weights[i]
                                val we = if (i == words.size - 1) e else s + ((e - s) * (acc / total)).toLong()
                                if (we <= gStart || ws >= gEnd) continue
                                val rs = (maxOf(ws, gStart) - gStart) * 1000
                                val re = (minOf(we, gEnd) - gStart) * 1000
                                subs.add(TextEvent(karaokeSpan(ov, words, i), rs, re))
                            }
                        }
                        continue
                    }

                    val relStartUs = (maxOf(s, gStart) - gStart) * 1000
                    val relEndUs = (minOf(e, gEnd) - gStart) * 1000
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
                // V16: dip-to-black — فوق الكلّ (النصّ يعتم معاه)
                if (clip["fade"] == true) {
                    if (blackBitmap == null) {
                        blackBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                            .apply { eraseColor(Color.BLACK) }
                    }
                    val fadeMs = minOf(350L, timelineMs / 2)
                    if (fadeMs > 0) overlayList.add(FadeBlackOverlay(blackBitmap!!, timelineMs, fadeMs))
                }
                if (overlayList.isNotEmpty()) {
                    effectsList.add(OverlayEffect(ImmutableList.copyOf(overlayList)))
                }

                seqBuilder.addItem(EditedMediaItem.Builder(mediaItem)
                    .setEffects(Effects(audioProcessors, effectsList))
                    .build())
            }

            // سلاسل الصوت (voix off + موسيقى) تتمزج فوق الفيديو
            val sequences = ArrayList<EditedMediaItemSequence>()
            sequences.add(seqBuilder.build())
            sequences.addAll(audioSequences(audio.filter { (it["kind"] as? String) == "voice" }))
            sequences.addAll(audioSequences(audio.filter { (it["kind"] as? String) == "music" }))

            val composition = Composition.Builder(sequences).build()
            val started = SystemClock.elapsedRealtime()
            val transformer = Transformer.Builder(this)
                .addListener(object : Transformer.Listener {
                    override fun onCompleted(composition: Composition, r: ExportResult) {
                        finishTracked {
                            it.success(mapOf(
                                "ms" to (SystemClock.elapsedRealtime() - started),
                                "output" to output,
                            ))
                        }
                    }

                    override fun onError(c: Composition, r: ExportResult, e: ExportException) {
                        File(output).delete() // ما نخلّيوش ملف نصّو
                        finishTracked { it.error("export_failed", e.message, null) }
                    }
                })
                .build()
            startTracked(transformer, result) { transformer.start(composition, output) }
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
            val transformer = Transformer.Builder(this)
                .addListener(object : Transformer.Listener {
                    override fun onCompleted(composition: Composition, r: ExportResult) {
                        finishTracked {
                            it.success(mapOf(
                                "ms" to (SystemClock.elapsedRealtime() - started),
                                "output" to output,
                            ))
                        }
                    }

                    override fun onError(c: Composition, r: ExportResult, e: ExportException) {
                        File(output).delete() // ما نخلّيوش ملف نصّو
                        finishTracked { it.error("export_failed", e.message, null) }
                    }
                })
                .build()
            startTracked(transformer, result) { transformer.start(edited, output) }
        } catch (e: Exception) {
            result.error("export_exception", e.message, null)
        }
    }
}
