# --- Flutter / Dart embedding ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Uygulama native köprüleri
-keep class com.mesutbyrm.canlifal.** { *; }

# Crash raporları için satır numaraları
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# --- Gson / JSON serileştirme ---
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.gson.**

# --- Firebase / Google Play Services / AdMob ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**

# --- Agora RTC ---
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# --- WebRTC / LiveKit ---
-keep class org.webrtc.** { *; }
-keep class io.livekit.** { *; }
-dontwarn org.webrtc.**
-dontwarn io.livekit.**

# --- Tencent TRTC ---
-keep class com.tencent.** { *; }
-keep class com.tencent.trtc.** { *; }
-keep class com.tencent.liteav.** { *; }
-dontwarn com.tencent.**

# --- audio_service / Media3 ExoPlayer ---
-keep class com.ryanheise.audioservice.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# --- OneSignal ---
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# --- OkHttp / Okio (çoğu plugin transitif) ---
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# --- Kotlin / coroutines ---
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

# --- Stripe / WebView / diğer yaygın uyarılar ---
-dontwarn android.media.**
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
