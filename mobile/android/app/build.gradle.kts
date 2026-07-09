import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.mesutbyrm.canlifal"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.mesutbyrm.canlifal"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            // Play Store hedefi: yalnızca 64-bit ARM (~%40 daha küçük APK; minSdk 24).
            abiFilters += listOf("arm64-v8a")
        }
    }

    buildFeatures {
        buildConfig = false
    }

    bundle {
        language { enableSplit = true }
        density { enableSplit = true }
        abi { enableSplit = true }
    }

    packaging {
        jniLibs {
            pickFirsts += listOf(
                "**/libliteavsdk.so",
                "**/libc++_shared.so",
            )
            // ffmpeg_kit / plugin AAR'ları tüm ABI'leri getirir; yalnızca arm64 bırak.
            excludes += listOf(
                "lib/armeabi-v7a/**",
                "lib/x86/**",
                "lib/x86_64/**",
                "lib/armeabi-v7a/libliteavsdk.so",
                "lib/x86_64/libliteavsdk.so",
                // Agora AI/eklenti modülleri (~45MB) — temel ses/video RTC yeterli.
                // libagora_ffmpeg.so DAHİL EDİLMELİ — libagora-rtc-sdk.so buna bağlıdır.
                "**/libagora_clear_vision_extension.so",
                "**/libagora_lip_sync_extension.so",
                "**/libagora_spatial_audio_extension.so",
                "**/libagora_ai_noise_suppression_extension.so",
                "**/libagora_ai_noise_suppression_ll_extension.so",
                "**/libagora_segmentation_extension.so",
                "**/libagora_face_capture_extension.so",
                "**/libagora_ai_echo_cancellation_extension.so",
                "**/libagora_audio_beauty_extension.so",
                "**/libagora_ai_echo_cancellation_ll_extension.so",
                "**/libagora_content_inspect_extension.so",
                "**/libagora_video_av1_encoder_extension.so",
                "**/libagora_video_quality_analyzer_extension.so",
                "**/libagora_face_detection_extension.so",
                "**/libagora_screen_capture_extension.so",
            )
            useLegacyPackaging = false
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.media3:media3-exoplayer:1.5.1")
}

// Agora ekran paylaşımı modülü (~15MB + MEDIA_PROJECTION) — sesli oda için gerekmez.
configurations.configureEach {
    exclude(group = "io.agora.rtc", module = "full-screen-sharing-special")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn(
        "google-services.json bulunamadı — Google Sign-In ApiException 10 (DEVELOPER_ERROR) " +
            "riski. Firebase Console'dan indirip android/app/ altına koyun.",
    )
}
