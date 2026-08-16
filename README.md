# Flutter Snap

A compact capstone sample demonstrating Flutter integration with Firebase and
common platform plugins. Users authenticate, capture and crop a photo, upload
it to Cloud Storage, create a Firestore document, and receive a transformed
image from a Cloud Function. The app also demonstrates Remote Config,
Analytics, Crashlytics, Performance Monitoring, Messaging, localization,
routing, shared preferences, and responsive layouts.

## Requirements

- Flutter 3.47.0 stable / Dart 3.13.0
- Android Studio with an Android SDK and JDK 17 or newer
- Node.js 22 for Firebase Functions
- Firebase CLI
- A Firebase project configured for the target platforms

Run `flutterfire configure` when connecting a different Firebase project. Do
not commit service-account credentials or the `STABILITY_API_KEY`; the latter
must be configured as a Cloud Functions secret.

## Run and verify

```shell
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run
```

Verified build targets:

```shell
flutter build apk --debug
flutter build web --release
```

The Windows target is currently blocked by an upstream Firebase C++ Firestore
linker issue involving `_Avx2WmemEnabled`. Track the open issue at
https://github.com/firebase/firebase-cpp-sdk/issues/1798. iOS, macOS, and Linux
must be built and tested on suitable host toolchains.

## Firebase backend

The checked-in rules use least privilege for the sample:

- authenticated users can read snaps;
- users can create and delete only their own snap documents;
- uploads are restricted to authenticated image creation under
  `snaps/{uid}/`, with a 10 MB limit;
- client document updates are denied because the Admin Cloud Function owns the
  `processed` and `url` fields.

Validate locally before deploying:

```shell
firebase emulators:start --only auth,functions,firestore,storage
```

Install and verify the Node.js functions:

```shell
cd firebase-functions
npm install
npm run lint
npm audit --omit=dev
```

Deploy intentionally from the repository root:

```shell
firebase deploy --only firestore:rules,storage,functions,remoteconfig
```

## Generated files

Regenerate localization sources and launcher icons with:

```shell
flutter gen-l10n
dart run flutter_launcher_icons
```

The application deliberately keeps a small, feature-oriented structure for
teaching. If it grows beyond this capstone scope, move Firebase access behind
services/repositories and inject those dependencies into view models before
adding more screens.
