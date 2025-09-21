plugins {
    id("com.android.application")
    id("kotlin-android")
    // O Flutter Gradle Plugin deve ser aplicado após os plugins do Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.csapp"
    // Definindo um valor fixo para o compileSdk para garantir que o editor o encontre.
    // O valor 'flutter.compileSdkVersion' às vezes causa problemas de análise no editor.
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "br.com.colegiosantoantonio.educsa"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Adicione sua própria configuração de assinatura para a build de release.
            // Assinando com as chaves de debug por enquanto, para que `flutter run --release` funcione.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
