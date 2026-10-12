# Captures d'écran Steam (8 à 10)

Méthode reproductible (vrai jeu, pas de truquage du gameplay, interface propre) :
```
"C:\Program Files\Godot\Godot.exe" --path . --resolution 1920x1080 res://src/debug/capture.tscn -- --time=<s> --clean --out=steam_assets/screenshots/<nom>.png [options]
```
`--clean` retire la surcouche de debug (FPS) et les barres de touches de manette. `--resolution 1920x1080` donne la bonne taille.
Options de scène : `--character=<id>`, `--danger=N`, `--boss=shogun|ronin`, `--coop`, `--shop`, `--levelup`, `--waveend`, `--characters`, `--progression`, `--menu`, `--arrival`.
**Ne pas utiliser `--stress`** pour les images finales : sa horde est artificielle. Les parties sont jouées par un bot ; le moment (`--time`) se choisit en regardant plusieurs essais.
Réserve : la capture n'a pas de pause sur l'action ; il faut parfois plusieurs essais pour un bon cadrage. Retirer les armes `TEMP_PLAYTEST_*` avant les images finales.

| # | Nom de fichier | Ce qu'elle montre | Option | Statut |
|---|---|---|---|---|
| 1 | `01_combat_horde.png` | Combat dense, armes peintes, horde sur l'arène | run normale, `--time` 60-120 | à créer |
| 2 | `02_boss.png` | Combat de boss avec sa barre | `--boss=shogun` | à créer |
| 3 | `03_shop.png` | Boutique entre deux vagues (pilier du design) | `--shop` | à créer |
| 4 | `04_level_up.png` | Choix de niveau supérieur (cartes avec icônes) | `--levelup` | à créer |
| 5 | `05_character_select.png` | Sélection du personnage et des armes | `--characters` | à créer |
| 6 | `06_seals.png` | Écran des sceaux (6 dangers, portail coloré) | `--danger=5` | à vérifier |
| 7 | `07_coop.png` | Coop locale à deux, écran partagé | `--coop` | à créer |
| 8 | `08_progression.png` | Progression et déblocages | `--progression` | à créer |
| 9 | `09_menu.png` | Menu principal (scène peinte, logo) | `--menu` | à créer |
| 10 | `10_wave_clear.png` | Fin de vague, récompenses | `--waveend` | à créer |

Ordre conseillé sur la page : 1, 2, 3, 4, 7, 5, 6, 8, 9, 10 (le combat et le boss en premier).
