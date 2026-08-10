import java.util.Base64
import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val releaseKeystoreFile = file("release.keystore")

/**
 * Upload keystore: local [key.properties] + [release.keystore], or CI env vars
 * (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS,
 * ANDROID_KEY_PASSWORD). Release builds must never fall back to debug signing.
 */
fun ensureReleaseKeystoreConfigured(): Boolean {
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        return true
    }
    val base64 = System.getenv("ANDROID_KEYSTORE_BASE64")?.trim().orEmpty()
    if (base64.isEmpty()) return false

    val storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")?.trim().orEmpty()
    val keyAlias = System.getenv("ANDROID_KEY_ALIAS")?.trim().orEmpty()
    val keyPassword = System.getenv("ANDROID_KEY_PASSWORD")?.trim().orEmpty()
    if (storePassword.isEmpty() || keyAlias.isEmpty() || keyPassword.isEmpty()) {
        return false
    }

    val decoded = Base64.getDecoder().decode(base64.replace(Regex("\\s"), ""))
    releaseKeystoreFile.outputStream().use { it.write(decoded) }

    keystoreProperties["storeFile"] = releaseKeystoreFile.name
    keystoreProperties["storePassword"] = storePassword
    keystoreProperties["keyAlias"] = keyAlias
    keystoreProperties["keyPassword"] = keyPassword
    return true
}

val hasReleaseKeystore = ensureReleaseKeystoreConfigured()

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
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
            excludes += listOf(
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
            if (!hasReleaseKeystore) {
                throw GradleException(
                    "Release build requires Play upload keystore. " +
                        "Provide android/key.properties + app/release.keystore locally, " +
                        "or set ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, " +
                        "ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD. " +
                        "See android/key.properties.example. " +
                        "Debug signing is not allowed for release builds.",
                )
            }
            signingConfig = signingConfigs.getByName("release")
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
