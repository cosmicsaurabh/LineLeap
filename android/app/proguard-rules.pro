# Flutter-specific proguard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugin classes
-keep class * extends io.flutter.embedding.engine.FlutterPlugin { *; }

# Hive database
-keep class com.google.protobuf.** { *; }
-keep class * extends com.google.protobuf.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep model classes
-keep class com.lineleapp.** { *; }
-keep class lineleap.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom application classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep view constructors for inflation from XML
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
