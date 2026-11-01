# Flutter Core & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# JNA & Vosk Speech Recognition
-keep class com.sun.jna.** { *; }
-keepclassmembers class * extends com.sun.jna.** { *; }
-keep class org.vosk.** { *; }
-dontwarn java.awt.**

# Drift & SQLite FFI bindings
-keep class io.simonbinder.sqlite3.** { *; }
-keep class com.sqlite3.** { *; }
-keep class * extends com.sqlite3.** { *; }
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# Keep Drift data classes, tables and companions
-keep class ** extends drift.** { *; }
-keep class * implements drift.GeneratedColumn { *; }
-keep class * implements drift.Table { *; }
-keep class * implements drift.DataClass { *; }

# Flutter Security & Biometrics
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**
