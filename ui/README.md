# ORIGIN Helper UI

The ORIGIN Helper UI is the Flutter-based desktop frontend for ORIGIN Helper, a Linux laptop-management utility.

## Current Features

- Dark-themed dashboard interface.
- System information dashboard layout.
- Performance mode selector with Quiet, Balanced, and Performance options.
- Basic UI state changes when selecting a performance mode.
- Linux desktop support through Flutter.

## Built With

- Flutter
- Dart
- Material Design

## Run Locally

Make sure Flutter and the Linux desktop development dependencies are installed.

From the `ui/` directory, run:

```bash
flutter pub get
flutter run -d linux
```

## Current Status

The UI is an early prototype. Performance mode selection currently changes only the interface state; it does not control actual hardware settings.

The Flutter UI is not yet connected to the C++ backend.

## Planned Work

- Connect the UI to the C++ backend.
- Display live hardware and battery information.
- Implement functional laptop-control features as backend support becomes available.
- Improve dashboard layout and desktop integration.
