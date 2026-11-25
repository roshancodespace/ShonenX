-dontwarn com.google.android.play.core.**
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses, RuntimeVisibleAnnotations, AnnotationDefault

-keep class com.roshancodespace.shonenx.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }

# Fix WorkManager / RoomDatabase reflection crash under R8
-keep class androidx.startup.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }

# JNI / Native / Rust / MediaKit / Isar / RuntimeBridge plugins
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
-keep,includedescriptorclasses class org.rustls.platformverifier.** { *; }
-keep class com.flutter_rust_bridge.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-keep class com.alexmercerind.media_kit.** { *; }
-keep class com.alexmercerind.media_kit_video.** { *; }
-keep class com.alexmercerind.mediakitandroidhelper.** { *; }
-keep class dev.isar.** { *; }
-keep class com.ryan.runtimebridge.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class uz.shs.better_player_plus.** { *; }
-keep class com.abandoft.webview_all_android.** { *; }
-keep class com.okmsbun.flutter_device_apps_android.** { *; }
-keep class soko.ekibun.flutter_qjs.** { *; }

# Gson
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
