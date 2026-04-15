@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

if exist "%SCRIPT_DIR%local.env.bat" (
  call "%SCRIPT_DIR%local.env.bat"
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

flutter pub get
if errorlevel 1 (
  echo Echec de flutter pub get.
  pause
  exit /b 1
)

flutter run -d edge --web-port 3000 --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%

endlocal
