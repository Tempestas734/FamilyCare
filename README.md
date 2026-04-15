# health_app

Application Flutter de suivi sante.

## Lancement rapide sur Edge

1. Copiez `local.env.bat.example` en `local.env.bat`.
2. Remplissez `SUPABASE_URL` et `SUPABASE_ANON_KEY`.
3. Lancez `run_edge.bat`.

Le script demarre l'application Flutter Web directement dans Microsoft Edge.

## GitHub

Le depot git a ete initialise localement. Pour publier sur GitHub :

```powershell
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin <URL_DU_REPO_GITHUB>
git push -u origin main
```

## Notes

- `local.env.bat` est ignore par git pour eviter de publier les variables locales.
- Les dossiers `build/` et autres fichiers generes ne sont pas versionnes.
