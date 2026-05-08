## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

## Sqflite
-keep class com.tekartik.sqflite.** { *; }

## OneSignal
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

## Awesome Notifications
-keep class me.carda.awesome_notifications.** { *; }
-dontwarn me.carda.awesome_notifications.**

## just_audio
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**

## audio_service
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**

## Keep all model classes from being stripped
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
