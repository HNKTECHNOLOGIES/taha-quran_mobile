# quran_mobile

**TAHA — طه** : application Flutter (Android / iOS) pour lire le **Saint Coran** hors connexion.

Nom technique du projet : `quran_mobile` (inchangé).

Logo / icône : `assets/branding/taha_logo.png` (généré pour Android, iOS et Web via `flutter_launcher_icons`).

## Fonctionnalités (livrées)

- **UC01** — Liste des 114 sourates (nom arabe, translittération, nombre de versets)
- **UC02** — Lecture d’une sourate (RTL, grande police, médaillons, séparateurs, nav. sourates)
- **UC03** — Traduction française **al-quran.fr Édition 1.1 (CC BY 4.0)** hors ligne
- **UC09–11** — Favoris, reprise de lecture, marque-pages (stockage local)
- **UC12** — Lecteur audio verse-par-verset (`just_audio`) + 3 récitateurs (everyayah.com)

## Stack

- Flutter / Dart
- Clean Architecture (features)
- Riverpod
- SQLite (`sqflite`) — seed depuis assets au premier lancement
- `just_audio` — récitation streamée par verset
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
| `assets/quran/AUDIO_SOURCES.md` | Catalogue récitateurs / URLs everyayah |

Les versets arabes et les traductions ne sont **jamais** générés ni modifiés par une IA.

## Audio (UC12)

- Fichiers **par verset** : `https://everyayah.com/data/{folder}/{SSS}{AAA}.mp3`
- Récitateurs : Mishary Rashid Alafasy, Abdul Basit Abdus Samad, Maher Al-Muaiqly
- Streamés (non embarqués) ; attribution « Audio : everyayah.com »
- Voir `assets/quran/AUDIO_SOURCES.md`

## Licence du texte

- Arabe : [licence Tanzil](https://tanzil.net/docs/license)
- Traduction FR : [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — attribution « al-quran.fr, Données ouvertes, Édition 1.1 »
- Polices Amiri / Source Serif 4 : SIL Open Font License
- Audio : everyayah.com (streaming, non redistribué dans le binaire)
