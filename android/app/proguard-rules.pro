-verbose
-dontpreverify
-dontnote
-ignorewarnings

-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses, RuntimeVisibleAnnotations, AnnotationDefault, SourceFile, LineNumberTable

-keep class io.flutter.embedding.** { *; }
-keep class com.roshancodespace.shonenx.MainActivity { *; }

-keep class com.google.android.play.core.** { *; }

-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

-keep class com.ryan.runtimebridge.** { *; }
-keep class com.anymex.runtimehost.** { *; }
-keep class com.lagradost.cloudstream3.** { *; }
-keep interface com.lagradost.cloudstream3.** { *; }
-keepclassmembers class com.lagradost.cloudstream3.** { *; }
-keep class eu.kanade.tachiyomi.** { *; }
-keep interface eu.kanade.tachiyomi.** { *; }

-keep class androidx.appcompat.** { *; }
-keep interface androidx.appcompat.** { *; }
-keep class com.google.android.material.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.preference.** { *; }
-keep interface androidx.preference.** { *; }
-keep class androidx.fragment.** { *; }
-keep class androidx.core.** { *; }
-keep class androidx.savedstate.** { *; }
-keep interface androidx.savedstate.** { *; }
-keep class androidx.activity.** { *; }
-keep interface androidx.activity.** { *; }

-keep class ** implements kotlin.Metadata
-keep class ** extends kotlin.Metadata
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-keepclassmembers class kotlinx.coroutines.** { *; }
-keep class kotlinx.serialization.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

-keep class isar.** { *; }

-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
-keep,includedescriptorclasses class org.rustls.platformverifier.** { *; }

-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

-keep class is.xyz.mpv.** { *; }
-dontwarn is.xyz.mpv.**

-keep,allowoptimization class uy.kohesive.injekt.** { public protected *; }
-keep class app.cash.quickjs.** { *; }
-keep class org.mozilla.** { *; }
-dontwarn org.mozilla.**
-keep class org.schabi.newpipe.** { *; }

-keep class org.jsoup.** { *; }
-keepclassmembers class org.jsoup.nodes.Document { *; }
-keep class me.xdrop.fuzzywuzzy.** { *; }

-keep class rx.** { *; }
-keep class io.reactivex.** { *; }
-dontwarn rx.**

-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Suppress remaining misc warnings
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**