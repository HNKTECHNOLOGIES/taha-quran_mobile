# quran_mobile

Application Flutter (Android / iOS) pour lire le **Saint Coran** (القرآن الكريم) hors connexion.

## Fonctionnalités (livrées)

- **UC01** — Liste des 114 sourates (nom arabe, translittération, nombre de versets)
- **UC02** — Lecture d’une sourate (RTL, grande police, médaillons, séparateurs, nav. sourates)
- **UC03** — Traduction française **al-quran.fr Édition 1.1 (CC BY 4.0)** hors ligne

## Stack

- Flutter / Dart
- Clean Architecture (features)
- Riverpod
- SQLite (`sqflite`) — seed depuis assets au premier lancement
- UI FR / AR avec bascule RTL
- Texte arabe : source **Tanzil** (via `quran-json@3.1.2`), non modifié, checksum SHA-256

## Lancer

```bash
flutter pub get
flutter run
```

Web (démo) :

```bash
flutter run -d chrome --web-port 43123
```

## Tests

```bash
flutter test
flutter analyze
```

## Données coraniques

| Fichier | Rôle |
|---------|------|
| `assets/quran/quran_ar.json` | Texte arabe (Uthmani), 114 sourates / 6236 versets |
| `assets/quran/quran_ar.sha256` | Empreinte SHA-256 |
| `assets/quran/translations_fr.json` | Traduction FR al-quran.fr 1.1 (séparée) |
| `assets/quran/translations_fr.sha256` | Empreinte SHA-256 traduction |
| `assets/quran/TRANSLATION_FR_LICENSE.md` | CC BY 4.0 + attribution |
| `assets/quran/MANIFEST.json` | Métadonnées source / licence |

Les versets arabes et les traductions ne sont **jamais** générés ni modifiés par une IA.

## Licence du texte

- Arabe : [licence Tanzil](https://tanzil.net/docs/license)
- Traduction FR : [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — attribution « al-quran.fr, Données ouvertes, Édition 1.1 »
- Polices Amiri / Source Serif 4 : SIL Open Font License
