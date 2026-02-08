-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects (both default and named) of serializable classes.
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep `INSTANCE.serializer()` of serializable objects.
-if @kotlinx.serialization.Serializable class ** {
    public static ** INSTANCE;
}
-keepclassmembers class <1> {
    public static <1> INSTANCE;
    kotlinx.serialization.KSerializer serializer(...);
}
-keepattributes Signature
-keep class uy.kohesive.injekt.** { *; }
-keep class eu.kanade.tachiyomi.** { *; }
-keep class com.aayush262.dartotsu_extension_bridge.** { *; }
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keep class kotlinx.** { *; }
-keepclassmembers class uy.kohesive.injekt.api.FullTypeReference {
    <init>(...);
}

-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class androidx.preference.** { *; }
# --- Okio (BufferedSource etc.) ---
-keep class okio.** { *; }
-dontwarn okio.**

-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keep class org.jsoup.** { *; }
-keepclassmembers class org.jsoup.nodes.Document { *; }

-keepattributes RuntimeVisibleAnnotations,AnnotationDefault