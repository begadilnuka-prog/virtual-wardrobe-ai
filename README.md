# Virtual Wardrobe AI

Premium Flutter MVP for:

- uploading wardrobe items
- organizing personal clothing collections
- generating outfit suggestions from saved items
- manually building looks
- saving favorite outfit combinations

## Tech

- Flutter
- Provider
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- SharedPreferences fallback for demo mode

## Firebase Setup

1. Add native Firebase config files to your Flutter platforms.
2. Enable Email/Password authentication.
3. Enable Firestore and Firebase Storage.
4. Run `flutter pub get` and launch the app.

If Firebase is not configured, the app falls back to a local demo mode so the MVP flows still work.
