# Google Play delivery

Android application: `app.iconstudio.icon_studio`.
The Google Play build is `1.0.1+3`. It adds an in-app privacy-policy link to the existing 1.0.1 functionality.

## Build

Use Flutter 3.35.7, a complete JDK 17, and Android SDK 36. Configure a private `android/key.properties` file as described in README.md, then run:

```sh
CI=true flutter pub get
CI=true flutter analyze
CI=true flutter test
CI=true flutter build appbundle --release
```

The bundle is written to `build/app/outputs/bundle/release/app-release.aab`.
Never commit the keystore, its password, or `android/key.properties`.

A separate Google Play upload key was created for this delivery. It is not the original APK signing key used for the GitHub v1.0.1 release. Google Play App Signing may use another distribution key; do not promise that the Play version can update the earlier sideloaded APK without reinstalling. Keep both signing arrangements separate and preserve confidential backups outside this public repository.

## Store graphics

`tool/create_store_graphics.py` renders the existing launcher vector into a 512-pixel store icon and creates the feature graphic. It requires CairoSVG.

`flutter test tool/play_store_screenshots.dart --no-pub` renders the real application widgets with local example creations. It creates four 1080 × 1920 PNGs in `build/play-store`. These are example compositions, not evidence of physical-device testing.

The privacy policy is published in `PRIVACY.md`, and the app exposes the same policy from its settings.

## Console

Application dashboard: https://play.google.com/console/u/0/developers/5383937199344392547/app/4973356963053854882/app-dashboard

The closed Alpha track is configured separately from production. Adding an email address to its tester list does not activate downloads: the track needs a signed release, completed store declarations, and Google's publication/review workflow.
