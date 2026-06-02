# FamilyCare Mobile

FamilyCare is a Flutter mobile application for family health coordination. It centralizes family members, medications, appointments, calendar events, and doctor discovery in a single Android/iOS app backed by Supabase.

## Main Features

- authentication with Supabase
- family creation and member management
- medication planning and dose tracking
- shared calendar for appointments and medication events
- doctor search, profile viewing, and family-doctor linking
- family settings and account access

## Stack

- Flutter
- Dart
- Supabase
- `table_calendar`
- `qr_flutter`

## Project Structure

- `lib/main.dart`: app entry point and Supabase initialization
- `lib/screens/`: mobile screens
- `lib/services/`: Supabase and domain services
- `lib/widgets/`: reusable UI widgets
- `lib/theme/`: theme definitions
- `supabase/`: SQL scripts and backend notes

## Local Setup

Prerequisites:

- Flutter SDK
- Android Studio and/or Xcode
- a Supabase project with the required schema

Create `local.env.bat` from `local.env.bat.example` and fill in:

```bat
@echo off
set "SUPABASE_URL=https://your-project.supabase.co"
set "SUPABASE_ANON_KEY=your-anon-key"
```

## Run On Mobile

Android:

```powershell
flutter run --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
```

iOS:

```powershell
flutter run --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
```

You can also export the same values from your shell or CI before building.

## Cleanup Notes

- unused package declarations were removed from `pubspec.yaml`
- the default Flutter counter test was removed because it did not match this app
- the repository is now documented as a mobile app, not a web/Edge project
