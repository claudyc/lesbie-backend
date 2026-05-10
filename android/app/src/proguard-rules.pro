# ── Flutter ───────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Firebase ──────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# ── Stripe ────────────────────────────────────────────────────────────────────
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# ── Agora ─────────────────────────────────────────────────────────────────────
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# ── Image Picker + Camera ─────────────────────────────────────────────────────
-keep class androidx.camera.** { *; }

# ── Evite erè nan release build ───────────────────────────────────────────────
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable