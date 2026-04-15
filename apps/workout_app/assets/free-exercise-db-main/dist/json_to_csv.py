import json
import csv
from pathlib import Path
from typing import Any, List, Dict

# ====== CONFIG ======
INPUT_JSON = Path("exercises.json")                 # ton fichier JSON
OUTPUT_CSV = Path("exercise_library.csv")           # CSV à importer dans Supabase
EXTERNAL_SOURCE = "free-exercise-db"                # valeur fixe pour ton dataset

# Mets ici le préfixe "racine" que TU veux dans Storage (optionnel)
# Exemple final: free-exercise-db/exercises/3_4_Sit-Up/0.jpg
STORAGE_ROOT = f"{EXTERNAL_SOURCE}/exercises"

CSV_FIELDS = [
    "name",
    "category",
    "difficulty",
    "force",
    "mechanic",
    "equipment",
    "primary_muscles",
    "secondary_muscles",
    "instructions",
    "media_paths",
    "external_source",
    "external_id",
    "is_active",
]

# ====== HELPERS ======
def to_storage_key(img_path: str) -> str:
    """
    Convertit un chemin image venant du JSON (ex: '3_4_Sit-Up/0.jpg')
    ou un path Windows en clé Storage stable:
      free-exercise-db/exercises/3_4_Sit-Up/0.jpg
    """
    if not img_path:
        return ""

    p = str(img_path).strip().replace("\\", "/").lstrip("/")

    # Le dataset fournit souvent "3_4_Sit-Up/0.jpg" (sans 'exercises/')
    # Si jamais tu as déjà 'exercises/...', on évite de dupliquer.
    if p.lower().startswith("exercises/"):
        rel = p[len("exercises/"):]
    else:
        rel = p

    # Construit la clé finale
    return f"{STORAGE_ROOT}/{rel}"

def to_pg_text_array(values: Any, transform=None) -> str:
    """
    Convertit une liste Python vers un literal PostgreSQL text[] dans un CSV.
    Format : {"a","b","c"}
    """
    if not isinstance(values, list) or len(values) == 0:
        return ""

    out: List[str] = []
    for v in values:
        if v is None:
            continue
        s = str(v).strip()
        if not s:
            continue

        if transform is not None:
            s = transform(s)
            if not s:
                continue

        # échappe les guillemets pour un array PG
        s = s.replace('"', '\\"')
        out.append(f'"{s}"')

    if not out:
        return ""
    return "{" + ",".join(out) + "}"

def normalize_json(data: Any) -> List[Dict[str, Any]]:
    """
    Accepte:
    - une liste d'exercices
    - ou un dict {"exercises": [...]}
    """
    if isinstance(data, dict) and "exercises" in data and isinstance(data["exercises"], list):
        return data["exercises"]
    if isinstance(data, list):
        return data
    raise ValueError("Le JSON doit être une liste d'exercices ou un objet { 'exercises': [...] }")

# ====== MAIN ======
def main():
    data = json.loads(INPUT_JSON.read_text(encoding="utf-8"))
    exercises = normalize_json(data)

    rows: List[Dict[str, str]] = []

    for ex in exercises:
        if not isinstance(ex, dict):
            continue

        name = str(ex.get("name", "")).strip()
        category = str(ex.get("category", "")).strip()
        external_id = str(ex.get("id", "")).strip()

        # Champs requis
        if not name or not category or not external_id:
            continue

        row = {
            "name": name,
            "category": category,
            "difficulty": str(ex.get("level", "")).strip(),
            "force": str(ex.get("force", "")).strip(),
            "mechanic": str(ex.get("mechanic", "")).strip(),
            "equipment": str(ex.get("equipment", "")).strip(),

            # Arrays text[]
            "primary_muscles": to_pg_text_array(ex.get("primaryMuscles", [])),
            "secondary_muscles": to_pg_text_array(ex.get("secondaryMuscles", [])),
            "instructions": to_pg_text_array(ex.get("instructions", [])),
            "media_paths": to_pg_text_array(ex.get("images", []), transform=to_storage_key),

            "external_source": EXTERNAL_SOURCE,
            "external_id": external_id,
            "is_active": "true",
        }

        rows.append(row)

    with OUTPUT_CSV.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_FIELDS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"✅ CSV généré: {OUTPUT_CSV} | lignes: {len(rows)}")
    print(f"ℹ️ Exemple media_paths: {rows[0]['media_paths'] if rows else 'N/A'}")

if __name__ == "__main__":
    main()
