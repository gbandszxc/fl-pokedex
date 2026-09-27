import com.android.build.gradle.internal.api.BaseVariantOutputImpl
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// release 签名：android/key.properties 存在时启用（本机开发 / CI 注入 Secrets 生成），
// 缺失时回退 debug 签名，保证任何机器检出后可直接构建
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.github.gbandszxc.fl_pokedex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // 分包不由这里手写 splits：Flutter 插件在默认模式会设 ndk.abiFilters，与 splits 互斥冲突；
    // 由 CLI `flutter build apk --release --split-per-abi` 驱动（插件内部自动配置 splits.abi，
    // 含 v7a / arm64-v8a / x86_64，不产 universal 包）。真机装 arm64-v8a，MuMu 等模拟器装 x86_64。
    // split 时 Flutter 自动为各包 versionCode 追加 1000 * ABI 序号，避免互相覆盖安装。
    // （https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions）

    if (hasReleaseSigning) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
                // v2 覆盖 API 24+，v3 额外带回密钥轮换能力（旧设备自动忽略 v3 块）
                enableV2Signing = true
                enableV3Signing = true
            }
        }
    }

    // 产物命名：Fl-PokeDex-<versionName>-<abi>-<release|debug>.apk（版本号取自 pubspec version）；
    // abi 取 splits 生成的 ABI filter 标识，universal 已关闭，兜底仅为防御
    applicationVariants.all {
        outputs.all {
            val output = this as BaseVariantOutputImpl
            val abi = output.filters.firstOrNull()?.identifier ?: "universal"
            output.outputFileName = "Fl-PokeDex-$versionName-$abi-${buildType.name}.apk"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.github.gbandszxc.fl_pokedex"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // key.properties 存在时用 release 签名，否则回退 debug 签名（`flutter run --release` 仍可用）
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
