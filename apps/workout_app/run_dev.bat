@echo off
setlocal

flutter run  ^
  --dart-define=SUPABASE_URL="https://kkhtavjnmwetvqmemsxp.supabase.co" ^
  --dart-define=SUPABASE_ANON_KEY="sb_publishable_vGp11-a364yvht7YlOjoiw_qlUWm0A5"

endlocal
