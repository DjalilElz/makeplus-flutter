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

# Google Tink, pulled in by flutter_secure_storage via
# androidx.security:security-crypto once AndroidOptions.encryptedSharedPreferences
# is enabled (see lib/data/services/secure_storage.dart).
#
# The plugin ships no consumer ProGuard rules of its own, and Tink resolves key
# managers and its shaded protobuf types reflectively. Under R8 (isMinifyEnabled)
# those get stripped/renamed, which does NOT fail the build — it fails at runtime,
# the first time the app touches secure storage, i.e. at login on a release build.
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-keepclassmembers class * extends com.google.crypto.tink.shaded.protobuf.GeneratedMessageLite {
    <fields>;
}
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# Annotations referenced by Tink but not present at runtime.
-dontwarn javax.annotation.**
-dontwarn com.google.errorprone.annotations.**
