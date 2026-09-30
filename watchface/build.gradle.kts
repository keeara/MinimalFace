plugins {
    alias(libs.plugins.android.application)
}

android {
    enableKotlin = false
    namespace = "com.example.minimalface"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.minimalface"
        // WFF v4 => Wear OS 6 (API 36) e successivi.
        minSdk = 36
        targetSdk = 36
        versionCode = 12
        versionName = "1.1.2"
    }

    buildTypes {
        debug {
            isMinifyEnabled = true
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}