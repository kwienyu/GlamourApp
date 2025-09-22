# Keep all ML Kit Text Recognition classes and inner classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.**$* { *; }

# Keep language-specific ML Kit text recognizers and their inner classes
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.chinese.**$* { *; }

-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.japanese.**$* { *; }

-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.korean.**$* { *; }

-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.**$* { *; }

# Keep all ML Kit common classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.mlkit.common.** { *; }

# Keep TensorFlow Lite classes and GPU delegate options including inner classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$** { *; }

# Keep Flutter plugin classes
-keep class io.flutter.plugins.** { *; }

# Keep CameraX classes
-keep class androidx.camera.** { *; }

# Keep all ML Kit model classes
-keepclassmembers class **.MLKitModel* { *; }

# Optional: keep all annotations
-keepattributes *Annotation*
