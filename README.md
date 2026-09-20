# Reminder App

A Flutter app for local, offline reminders: drink-water nudges, daily affirmations,
and your own custom reminders (medication, walking the dog, etc.). Every reminder
type shares the same scheduling model — either "all day" or a specific time window,
with an interval between notifications — and rotates through a pool of fun,
emoji-filled messages so it doesn't feel robotic.

## Features

- 💧 Water reminders, ✨ daily affirmations, and unlimited custom reminders
- Each reminder: all-day or a specific time window (e.g. 8am–10pm), plus an
  interval between notifications (1–12 hours)
- Turning a reminder on preserves the exact minute you enabled it (e.g. enable
  at 10:31 with a 1hr interval → fires at 11:31, 12:31, ...) instead of
  snapping to the top of the hour
- Messages are pulled from a shuffle bag (no repeats until the whole pool has
  been used) and refresh daily
- Per-reminder "send test notification now" button, plus a "1 min (test)"
  interval option for testing real scheduled delivery without waiting
- Settings tab with light/dark/system theme mode and a choice of color themes
- Works on Android and iOS

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- An editor (VS Code, Android Studio, etc.) with the Flutter/Dart plugins
- To run on a device or emulator: platform-specific setup below

Check your setup any time with:

```bash
flutter doctor
```

## Android setup

1. Install [Android Studio](https://developer.android.com/studio). During
   setup, choose the **Standard** install type — it pulls in the Android SDK,
   platform-tools, and a default emulator image.
2. From Android Studio's **SDK Manager → SDK Tools** tab, make sure
   **Android SDK Command-line Tools** and **NDK (Side by side)** are installed.
3. To run on a **physical phone**:
   - On the phone: Settings → About phone → tap "Build number" 7 times to
     unlock Developer Options, then Settings → Developer options → enable
     **USB debugging**.
   - Plug the phone in via USB and accept the "Allow USB debugging?" prompt.
   - Run `flutter devices` to confirm it's detected.
4. To run on an **emulator** instead: Android Studio → More Actions →
   Virtual Device Manager → Create Device, pick a phone profile and a recent
   system image.
5. From the project root:

   ```bash
   flutter pub get
   flutter run
   ```

6. **Important — exact alarm permission**: Android 12+ requires a separate,
   user-granted permission for exact-time scheduled notifications, on top of
   the normal notification permission. The app requests it, but on some
   Android versions you may need to manually enable it once: **Settings →
   Apps → Reminder App → Alarms & reminders → Allow**. Without this,
   reminders will silently fail to fire.

## iOS setup

Building for iOS **requires a Mac with Xcode installed** — this cannot be
done from Windows or Linux.

1. Install [Xcode](https://apps.apple.com/us/app/xcode/id497799835) from the
   Mac App Store, then open it once to accept the license and install
   additional components.
2. Install [Flutter](https://docs.flutter.dev/get-started/install/macos) on
   the Mac, then from the project root:

   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   ```

3. Open `ios/Runner.xcworkspace` (not `Runner.xcodeproj`) in Xcode.
4. Select the `Runner` target → **Signing & Capabilities** → sign in with
   your Apple ID and choose your personal team. A free Apple ID lets you run
   the app on your own device (re-sign every 7 days); a paid Apple Developer
   account removes that limit.
5. Plug in your iPhone, select it as the run destination in Xcode, and hit
   **Run** — or from the terminal:

   ```bash
   flutter run -d <your-iphone-name>
   ```

6. On first launch, accept the notification permission prompt.

## Project structure

```
lib/
  main.dart                    App entry point, initializes notifications
  app_shell.dart                Bottom-nav shell (Reminders / Settings tabs)
  home_screen.dart             Reminders tab UI: cards, add/edit dialogs
  settings_screen.dart         Settings tab UI: theme mode and color picker
  theme_controller.dart        Persisted theme preferences
  notification_service.dart    All scheduling logic (Android + iOS)
  reminder_settings.dart       Persisted settings for water/affirmations
  custom_reminder.dart         Model for user-created reminders
  custom_reminders_store.dart  Persistence for custom reminders
  interval_schedule_editor.dart Shared "interval + window" UI widget
  affirmations.dart            Message pools (affirmations, water messages)
  shuffle_bag.dart             Non-repeating random picker
```

## Running tests

```bash
flutter test
```
