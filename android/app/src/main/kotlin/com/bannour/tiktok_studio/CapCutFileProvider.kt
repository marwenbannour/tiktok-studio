package com.bannour.tiktok_studio

import androidx.core.content.FileProvider

/// FileProvider خاص بالتطبيق (class منفصلة باش ما تتعارضش مع providers
/// متاع share_plus ولا image_picker في الـmanifest).
class CapCutFileProvider : FileProvider()
