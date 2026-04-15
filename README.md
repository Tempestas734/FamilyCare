# FamilyCare

FamilyCare is a Flutter application designed to help households organize and monitor shared health-related activities in one place. The app focuses on family-centered care by combining member management, medication planning, medical appointments, and doctor discovery into a single experience.

## Overview

FamilyCare provides a central workspace for families who want to coordinate everyday healthcare tasks more efficiently. It allows users to create or join a family space, manage family members, track medication schedules, review upcoming health events in a calendar, and connect with doctors linked to the family.

## Core Features

- Family account onboarding with authentication powered by Supabase
- Family creation and member management
- Personal and family health overview from a shared home dashboard
- Medication creation, planning, and dose tracking
- Calendar view for appointments and medication events
- Doctor discovery, profile viewing, and family-doctor linking
- Settings and account access for everyday use

## Application Modules

### Authentication and Family Setup

Users can sign in, create a family, and register the first household administrator. The application uses Supabase authentication and stores family data in the backend.

### Family Management

FamilyCare supports adding, editing, and reviewing family members. This makes it easier to organize care information across parents, children, and other dependents.

### Medication Planning

The application includes dedicated medication screens for:

- adding medications
- assigning medications to family members
- defining intake schedules
- tracking active medication plans
- marking doses as taken

### Calendar and Health Timeline

The calendar aggregates:

- medical appointments
- medication reminders and scheduled doses

This gives families a single timeline for daily healthcare coordination.

### Doctor Discovery

Users can browse doctors, search by specialty or location, open doctor profiles, and attach doctors to a family context for easier follow-up.

## Tech Stack

- Flutter
- Dart
- Supabase
- `table_calendar`
- `flutter_map`
- `provider`
- `flutter_riverpod`

## Project Structure

Main application code is organized in:

- `lib/screens/` for application screens
- `lib/services/` for backend and domain services
- `lib/widgets/` for reusable UI components
- `lib/theme/` for visual styling
- `supabase/` for SQL schema files

## Local Setup

### Prerequisites

- Flutter SDK installed
- Microsoft Edge installed for web testing
- A Supabase project with the required tables and configuration

### Environment Configuration

1. Copy `local.env.bat.example` to `local.env.bat`.
2. Set your Supabase values:

```bat
@echo off
set "SUPABASE_URL=https://your-project.supabase.co"
set "SUPABASE_ANON_KEY=your-anon-key"
```

`local.env.bat` is ignored by git to avoid committing local credentials.

## Run the App

To start FamilyCare in Microsoft Edge:

```powershell
.\run_edge.bat
```

This script:

- loads local Supabase environment variables
- runs `flutter pub get`
- starts the Flutter web app in Edge on port `3000`

## Publish to GitHub

If you want to push the project to GitHub:

```powershell
git remote add origin <URL_DU_REPO_GITHUB>
git push -u origin main
```

## Notes

- Generated files and build outputs are excluded from version control where appropriate.
- Local secrets are kept out of the repository through `.gitignore`.
- Supabase configuration is required at runtime through `--dart-define` values injected by the launch script.
