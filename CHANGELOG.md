# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.0.0+1] - 2026-01-04

### Fixed
- **Android Build System:** Resolved build failures caused by Java/Gradle incompatibilities.
    - Enforced use of Java 17 for the build environment.
    - Fixed typo in `android/app/build.gradle.kts` (`targetSdk` -> `targetSdkVersion`).
- **Dependency Patch (`flutter_nearby_connections`):**
    - Moved dependency to local `packages/` directory.
    - Removed deprecated Android v1 Embedding code (`Registrar`) to fix compilation errors.
    - Injected `namespace` configuration via `android/build.gradle.kts` to satisfy Android Gradle Plugin requirements.
    - Forced JVM Target 17 for the plugin to match the app's configuration.

### Added
- `BUILD_INSTRUCTIONS.md`: Documentation for environment setup and build commands.
- `packages/flutter_nearby_connections`: Local copy of the plugin with necessary patches.
