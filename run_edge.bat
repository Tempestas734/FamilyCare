@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "EDGE_PROFILE_DIR=%SCRIPT_DIR%.dart_tool\edge_profile"

if exist "%SCRIPT_DIR%local.env.bat" (
  call "%SCRIPT_DIR%local.env.bat"
)

if not exist "%EDGE_PROFILE_DIR%" (
  mkdir "%EDGE_PROFILE_DIR%"
)

if "%SUPABASE_URL%"=="" (
  echo SUPABASE_URL n'est pas defini.
  echo Creez local.env.bat a partir de local.env.bat.example.
  pause
  exit /b 1
)

if "%SUPABASE_ANON_KEY%"=="" (
  echo SUPABASE_ANON_KEY n'est pas defini.
  echo Creez local.env.bat a partir de local.env.bat.example.
  pause
  exit /b 1
)

echo Starting FamilyCare on Microsoft Edge...
flutter run -d edge --web-port 3000 --web-browser-flag=--user-data-dir=%EDGE_PROFILE_DIR% --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%

endlocal
