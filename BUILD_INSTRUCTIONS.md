# Build Setup & Troubleshooting

This document outlines the specific environment requirements and configurations needed to build the `xpong` project, specifically for Android.

## 1. Environment Requirements

### Java Development Kit (JDK) 17
The Android Gradle Plugin and the dependencies used in this project require **Java 17**. 
*   **Issue:** Newer versions (e.g., Java 25) cause build failures with Gradle.
*   **Solution:** Install JDK 17.

**macOS (via Homebrew):**
```bash
brew install --cask temurin@17
```

### Android SDK
The project requires specific Android SDK platforms and build tools.
*   **Platform:** `android-36`, `android-35`, `android-34`
*   **Build Tools:** `35.0.0`
*   **NDK:** Version `28.2.13676358` (installed side-by-side)

## 2. Local Patches & Workarounds

### `flutter_nearby_connections` Patch
The version of `flutter_nearby_connections` on pub.dev (v1.1.2) uses the deprecated Android v1 Embedding API (`PluginRegistry.Registrar`), which causes build failures in modern Flutter apps.

*   **Location:** `packages/flutter_nearby_connections`
*   **Changes:** 
    *   Removed `registerWith` method in `FlutterNearbyConnectionsPlugin.kt`.
    *   Removed import of `Registrar`.
    *   The package is linked locally in `pubspec.yaml`.

### Gradle Build Script Workarounds
The `flutter_nearby_connections` plugin also had issues with missing `namespace` declaration (required by newer Android Gradle Plugins) and mismatched JVM targets.

*   **File:** `android/build.gradle.kts`
*   **Fix:** A script was added to dynamically inject the `namespace` and force `sourceCompatibility`/`targetCompatibility` to **Java 17** for the plugin project during the build process.

## 3. Building the Project

Always ensure `JAVA_HOME` points to JDK 17 before running build commands.

### Build APK
```bash
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
flutter build apk
```

### Run on Android Device
```bash
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
flutter run
```
