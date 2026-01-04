# XPong Style Guide

This document defines the coding standards and conventions for the `xpong` project. Adhering to these guidelines ensures a consistent, readable, and maintainable codebase.

## 1. Dart & Flutter Conventions

We follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) and [Flutter Architectural Recommendations](https://docs.flutter.dev/perf/best-practices).

### 1.1 Naming Conventions

*   **Classes & Types:** `UpperCamelCase` (e.g., `NearbyManager`, `PongGame`).
*   **Variables & Functions:** `lowerCamelCase` (e.g., `ballPosition`, `requestPermissions()`).
*   **Private Members:** Prefix with an underscore `_` (e.g., `_isInitialized`, `_handleNetworkData()`).
*   **Files:** `snake_case.dart` (e.g., `nearby_manager.dart`).
*   **Constants:** `lowerCamelCase` for local/instance constants, `SCREAMING_SNAKE_CASE` only for rare global configuration if necessary (prefer `static const` in classes).

### 1.2 Formatting

*   **Indentation:** 2 spaces (Standard Dart/Flutter).
*   **Trailing Commas:** Use trailing commas for all multi-line function calls, constructor parameters, and widget trees to maintain clean diffs and proper formatting.
*   **Line Length:** Prefer a maximum of 80-120 characters.

## 2. Widget Practices

### 2.1 Use `const` Constructors
Always use `const` for widgets that do not change to improve performance.
```dart
const Text("XPong Lobby")
```

### 2.2 Stateful vs Stateless
*   Use `StatelessWidget` for UI that depends solely on configuration parameters.
*   Use `StatefulWidget` only when the widget needs to manage its own internal state (e.g., animation controllers, tickers, or ephemeral UI state).

### 2.3 `mounted` Check
Always check `if (mounted)` before calling `setState()` after an `await` point to avoid memory leaks or crashes.
```dart
_nearbyManager.onDevicesUpdated = () {
  if (mounted) setState(() {});
};
```

## 3. Architecture & State

### 3.1 Separation of Concerns
*   **Managers:** Business logic and external service interactions (e.g., `NearbyManager`) should be kept separate from the UI.
*   **Painters:** Complex custom drawing logic should be encapsulated in `CustomPainter` classes (e.g., `PongPainter`).

### 3.2 State Management
Currently, the project uses `setState()` for ephemeral state. If complexity grows, consider moving towards a more robust solution like `Provider` or `Riverpod`.

## 4. Documentation

*   Use `///` for documentation comments on public members.
*   Use `//` for internal implementation details.
*   Keep comments focused on *why* something is done rather than *what* is done.

## 5. Testing

*   All new features should be accompanied by corresponding widget or unit tests in the `test/` directory.
*   Follow the `Given/When/Then` structure for test descriptions.
