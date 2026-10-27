import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// مفتاح التوقيع للـrelease (key.properties ما يتبعثش في git)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// APK release موقّع بمفتاح debug = ما عادش تنجم تعمل mise à jour بالمفتاح الحقيقي
// (الناس يلزمهم يفسخو الـapp). على هذاك الـbuild release يطيح كان key.properties ناقص.
// للتجربة برك:  ALLOW_DEBUG_SIGNED_RELEASE=true flutter build apk --release
val wantsRelease = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true) || it.contains("Bundle", ignoreCase = true)
}
val allowDebugRelease = System.getenv("ALLOW_DEBUG_SIGNED_RELEASE") == "true"
if (wantsRelease && !hasReleaseKeystore && !allowDebugRelease) {
    throw GradleException(
        "key.properties ناقص: الـrelease لازم يتوقّع بمفتاحك. " +
        "شوف README (Signing) ولا، للتجربة برك، حطّ ALLOW_DEBUG_SIGNED_RELEASE=true."
    )
}

android {
    namespace = "com.bannour.tiktok_studio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications يستحقّو (java.time على Android قديم)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bannour.tiktok_studio"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // مفتاح الـrelease؛ الـdebug ما يتستعملش كان بـALLOW_DEBUG_SIGNED_RELEASE=true
            signingConfig = if (hasReleaseKeystore)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // محرّك export الفيديو (Lot 2): Media3 Transformer + Effect (نصّ على الفيديو)
    // 1.9.2 = نفس نسخة الـruntime اللي يجرّها video_player (مجموعة media3 تتوحّد
    // للأعلى)؛ لو خلّيناها 1.5.1 الكومپايل يختلف عن الـruntime → NoClassDefFound.
    val media3 = "1.9.2"
    implementation("androidx.media3:media3-transformer:$media3")
    implementation("androidx.media3:media3-effect:$media3")
    implementation("androidx.media3:media3-common:$media3")
    // FileProvider (إرسال الفيديو لـCapCut)
    implementation("androidx.core:core-ktx:1.13.1")
}
