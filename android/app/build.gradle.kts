plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.glamourapp"
    compileSdk = 35   // 🔥 updated for plugin requirements
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.glamourapp"
        minSdk = 23       // 🔥 updated for Firebase requirements
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Use your release signing config in production
            signingConfig = signingConfigs.getByName("debug") 

            // Disable R8/ProGuard and resource shrinking for ML Kit stability
            isMinifyEnabled = false
            isShrinkResources = false

            // Commented out ProGuard files because minification is disabled
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

dependencies {
    // Example dependencies (add only what your app uses)
    // ML Kit Text Recognition
    //implementation("com.google.mlkit:text-recognition:16.1.0")
    //implementation("com.google.mlkit:text-recognition-chinese:16.1.0")
    //implementation("com.google.mlkit:text-recognition-japanese:16.1.0")
    //implementation("com.google.mlkit:text-recognition-korean:16.1.0")
    //implementation("com.google.mlkit:text-recognition-devanagari:16.1.0")

    // Firebase (example)
    //implementation(platform("com.google.firebase:firebase-bom:32.2.2"))
    //implementation("com.google.firebase:firebase-auth-ktx")
    //implementation("com.google.firebase:firebase-firestore-ktx")

    // CameraX (example)
    //implementation("androidx.camera:camera-core:1.2.3")
   // implementation("androidx.camera:camera-camera2:1.2.3")
   // implementation("androidx.camera:camera-lifecycle:1.2.3")
}

flutter {
    source = "../.."
}
