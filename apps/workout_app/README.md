# Workout App (Standalone)

This app is independent from the main app UI, but uses the same Supabase project.

## Run

```bash
flutter run --project-dir apps/workout_app -t lib/main.dart \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Data Contract with Main App

This app writes workout sessions into `public.workout_sessions`:

- `family_id`
- `member_id`
- `workout_type`
- `duration_minutes`
- `estimated_calories`
- `started_at`
- `ended_at`

The main app can read and display these sessions (ex: feed, history, stats).
