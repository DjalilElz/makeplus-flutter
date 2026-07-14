# Flutter wraps its own engine rules; these cover the plugins this app uses.

# mobile_scanner / ML Kit barcode scanning — reflection-loaded, and the optional
# language models are absent at compile time.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin coroutines internals used by several plugins.
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-dontwarn kotlinx.coroutines.**

# Play Core is referenced by Flutter's deferred-components support, which this
# app does not use — the classes are genuinely absent.
-dontwarn com.google.android.play.core.**
