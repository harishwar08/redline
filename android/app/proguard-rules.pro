# REDLINE — R8/ProGuard keep rules for release shrinking.
# Most plugins ship consumer rules; these cover the ones that use reflection
# (Gson) or that R8 full-mode otherwise strips/warns on.

# ── flutter_local_notifications (serialises scheduled notifications via Gson) ──
-keep class com.dexterous.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ── Gson generic signatures / annotations ────────────────────────────────────
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses

# ── Silence R8 warnings for optional/transitive classes not on the classpath ──
-dontwarn com.google.android.play.core.**
-dontwarn javax.annotation.**
