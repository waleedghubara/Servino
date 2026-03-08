# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# FileProvider
-keep class androidx.core.content.FileProvider { *; }

# Exif (مهم لبعض أجهزة Oppo)
-keep class androidx.exifinterface.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Protobuf
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Audio
-keep class com.ryanheise.just_audio.** { *; }
-keep class xyz.luan.audioplayers.** { *; }

# Lottie
-keep class com.airbnb.lottie.** { *; }
-dontwarn com.airbnb.lottie.**

# Connectivity
-keep class io.flutter.plugins.connectivity.** { *; }

# Generic
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# R8 compatibility
-dontwarn java.nio.**
-dontwarn javax.annotation.**
-dontwarn javax.xml.**

# Play Core
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.splitinstall.**
# Zego & WebRTC (Exhaustive)
-keep class im.zego.** { *; }
-keep class com.zego.** { *; }
-keep class com.zegocloud.** { *; }
-keep class com.zegocloud.uikit.** { *; }
-keep class org.webrtc.** { *; }
-keep interface im.zego.** { *; }
-keep interface com.zegocloud.** { *; }
-keep interface com.zegocloud.uikit.** { *; }
-dontwarn im.zego.**
-dontwarn com.zego.**
-dontwarn com.zegocloud.**
-dontwarn com.zegocloud.uikit.**
-dontwarn org.webrtc.**
-dontwarn com.google.android.play.core.splitcompat.**