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

fun isPlaceholderSecret(value: String): Boolean {
    val v = value.trim()
    return v.isEmpty() ||
        v.equals("YOUR_STORE_PASSWORD", ignoreCase = true) ||
        v.equals("YOUR_KEY_PASSWORD", ignoreCase = true) ||
        v.equals("YOUR_KEY_ALIAS", ignoreCase = true) ||
        v.startsWith("YOUR_", ignoreCase = true)
}

/** [storeFile] — app modülüne göre; `release.keystore` → android/app/release.keystore */
fun resolveReleaseKeystoreFile(storeFilePath: String): java.io.File? {
    val p = storeFilePath.trim()
    if (p.isEmpty()) return null
    val candidates = listOf(
        file(p),
        rootProject.file("app/$p"),
        rootProject.file(p),
    )
    return candidates.firstOrNull { it.isFile }
}

/**
 * Upload keystore: local [key.properties] + [release.keystore], or CI env vars
 * (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS,
 * ANDROID_KEY_PASSWORD). Release builds must never fall back to debug signing.
 */
fun ensureReleaseKeystoreConfigured(): Boolean {
    keystoreProperties.clear()
    if (keystorePropertiesFile.isFile) {
        keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    } else {
        val base64 = System.getenv("ANDROID_KEYSTORE_BASE64")?.trim().orEmpty()
        if (base64.isEmpty()) return false

        val storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")?.trim().orEmpty()
        val keyAlias = System.getenv("ANDROID_KEY_ALIAS")?.trim().orEmpty()
        val keyPassword = System.getenv("ANDROID_KEY_PASSWORD")?.trim().orEmpty()
        if (
            storePassword.isEmpty() ||
            keyAlias.isEmpty() ||
            keyPassword.isEmpty() ||
            isPlaceholderSecret(storePassword) ||
            isPlaceholderSecret(keyPassword)
        ) {
            return false
        }

        val decoded = Base64.getDecoder().decode(base64.replace(Regex("\\s"), ""))
        releaseKeystoreFile.outputStream().use { it.write(decoded) }

        keystoreProperties["storeFile"] = releaseKeystoreFile.name
        keystoreProperties["storePassword"] = storePassword
        keystoreProperties["keyAlias"] = keyAlias
        keystoreProperties["keyPassword"] = keyPassword
    }

    val storePassword = keystoreProperties.getProperty("storePassword").orEmpty()
    val keyPassword = keystoreProperties.getProperty("keyPassword").orEmpty()
    val keyAlias = keystoreProperties.getProperty("keyAlias").orEmpty()
    val storeFilePath = keystoreProperties.getProperty("storeFile").orEmpty()
    if (
        isPlaceholderSecret(storePassword) ||
        isPlaceholderSecret(keyPassword) ||
        keyAlias.isBlank() ||
        storeFilePath.isBlank()
    ) {
        return false
    }

    val storeFile = resolveReleaseKeystoreFile(storeFilePath) ?: return false
    keystoreProperties["storeFile"] = storeFile.absolutePath
    return true
}

fun releaseKeystoreDiagnostic(): String {
    val lines = mutableListOf<String>()
    lines += "key.properties path: ${keystorePropertiesFile.absolutePath} " +
        "(exists=${keystorePropertiesFile.isFile})"
    val storePath = keystoreProperties.getProperty("storeFile").orEmpty()
    if (storePath.isNotBlank()) {
        lines += "storeFile resolved: $storePath (exists=${file(storePath).isFile})"
    } else {
        lines += "storeFile: (missing or not resolved)"
        lines += "Expected keystore: ${rootProject.file("app/release.keystore").absolutePath}"
    }
    val alias = keystoreProperties.getProperty("keyAlias").orEmpty()
    lines += "keyAlias: ${if (alias.isBlank()) "(missing)" else alias}"
    val sp = keystoreProperties.getProperty("storePassword").orEmpty()
    val kp = keystoreProperties.getProperty("keyPassword").orEmpty()
    lines += "storePassword: ${if (isPlaceholderSecret(sp)) "PLACEHOLDER or empty" else "set"}"
    lines += "keyPassword: ${if (isPlaceholderSecret(kp)) "PLACEHOLDER or empty" else "set"}"
    return lines.joinToString("\n  ")
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
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")
                val storePath = keystoreProperties.getProperty("storeFile").orEmpty()
                storeFile = if (storePath.isNotBlank()) file(storePath) else null
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
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

val releaseKeystoreErrorMessage =
    "Release build requires Play upload keystore. " +
        "Provide android/key.properties + app/release.keystore locally, " +
        "or set ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, " +
        "ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD. " +
        "See android/key.properties.example. " +
        "Debug signing is not allowed for release builds."

// Yapılandırma aşamasında değil — yalnızca release görevi çalışırken kontrol et
// (assembleDebug / CodeQL debug derlemesi keystore olmadan devam edebilir).
afterEvaluate {
    tasks.matching {
        val n = it.name
        n.contains("Release", ignoreCase = true) &&
            (n.contains("assemble", ignoreCase = true) ||
                n.contains("bundle", ignoreCase = true) ||
                n.contains("package", ignoreCase = true))
    }.configureEach {
        doFirst {
            if (!ensureReleaseKeystoreConfigured()) {
                throw GradleException(
                    releaseKeystoreErrorMessage +
                        "\n\nDiagnostics:\n  ${releaseKeystoreDiagnostic()}",
                )
            }
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
