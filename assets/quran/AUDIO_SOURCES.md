# Sources audio (récitation)

## Catalogue — fichiers **par verset** (everyayah.com)

| Récitateur | Dossier everyayah.com | Format URL |
|---|---|---|
| Mishary Rashid Alafasy | `Alafasy_128kbps` | `https://everyayah.com/data/Alafasy_128kbps/{SSS}{AAA}.mp3` |
| Abdul Basit Abdus Samad (Murattal) | `Abdul_Basit_Murattal_192kbps` | idem |
| Maher Al-Muaiqly | `MaherAlMuaiqly128kbps` | idem |

`SSS` = numéro de sourate sur 3 chiffres, `AAA` = numéro de verset sur 3 chiffres  
Exemple : sourate 1 verset 1 → `001001.mp3`

Vérifié HTTP 200 le 2026-10-25 pour `001001.mp3` des trois dossiers.

## Catalogue — fichiers **par sourate** (mp3quran.net)

| Récitateur | Serveur | Format URL |
|---|---|---|
| Badr Touarique (Badr bin Mohammad Al-Turki) | `cdn.mp3quran.net/audio/badr-turki/r1/` | `https://cdn.mp3quran.net/audio/badr-turki/r1/{SSS}.mp3` |

Vérifié HTTP 200 le 2026-11-03 pour `001.mp3`, `002.mp3`, `112.mp3`, `114.mp3`.

**Limitation** : sans fichiers de minutage, la sync. verset-par-verset n’est **pas** disponible pour ce récitateur (play/pause/stop + progression sourate uniquement).

## Conditions d’usage

- Les fichiers sont **streamés** (non redistribués dans le binaire de l’app).
- Hébergeurs publics : [everyayah.com](https://everyayah.com), [mp3quran.net](https://mp3quran.net).
- Attribution dans l’app selon la source active.
- Les fichiers de *timings* everyayah imposent un lien retour ; la sync. verse-par-verset utilise un MP3 = un verset.

## Hors périmètre actuel

- Téléchargement hors-ligne des MP3.
- Synchronisation exacte d’un fichier « sourate complète » sans minutage.
