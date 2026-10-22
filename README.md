# EasyAdd 2.0

A tape measure calculator for feet, inches and fractions, rebuilt in Flutter.

- Bundle id: `com.anthonyercolano.constructioncalculator`
- App Store: https://apps.apple.com/us/app/easyadd/id6755840605
- Build plan: [scaffold.md](scaffold.md)

## Develop

```sh
flutter pub get
flutter run            # iOS simulator or Android emulator
flutter test
flutter analyze
```

Regenerate icons and splash after changing `assets/icon/` or the colors in `pubspec.yaml`:

```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Requires Flutter 3.41.3 (Dart 3.11).
