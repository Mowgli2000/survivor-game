# Rapport de la nuit du 2026-10-05

Tâches choisies par le dev : points « avant démo », tests au simulateur, améliorations visuelles. Tout est sur des branches à part, **rien n'est fusionné dans `playtest/2026-10-05` ni poussé**.

| Branche | Contenu | Base |
|---|---|---|
| `night/demo-prep` | sauvegarde sûre, numéro de version | `playtest/2026-10-05` |
| `night/visuals` | explosions, mort des monstres, cristal de matériau, ce rapport | `night/demo-prep` (contient donc les deux) |
| `night/sim` | bot « Zone » et option mode infini du simulateur | `playtest/2026-10-05` |

Pour tout essayer : fusionner `night/visuals` puis `night/sim` dans `playtest/2026-10-05`.

## 1. Points « avant démo »
- **Sauvegarde sûre** (`SafeFile`, `src/core/safe_file.gd`) :
  - le profil et les paramètres sont d'abord écrits dans un fichier temporaire ;
  - l'ancien fichier est gardé en copie de secours (`.bak`), puis remplacé d'un coup ;
  - un plantage pendant l'écriture ne peut plus effacer le profil ;
  - une sauvegarde abîmée est remplacée par la copie de secours ;
  - supprimer le fichier remet toujours le profil à zéro.
  - 6 tests, dont un qui « corrompt » le profil et vérifie qu'on retrouve la sauvegarde précédente.
- **Numéro de version** : `v0.9.0` en bas à droite du menu (`application/config/version`, à monter à chaque version de test). Capture : `art_tests/nuit_menu_version.png`.
- **FPS (stress test)** :
  - début de nuit, version de playtest : ~95 FPS ; `develop` d'avant la session donne la même chose (~94) en mesure alternée. **Pas de régression** : la machine est plus lente qu'en session 7 (112).
  - Répartition du temps physique : ennemis ~45 %, projectiles ~55 %.
  - Après les nouveaux visuels : **~101-103 FPS**, et **750 appels de dessin au lieu de ~1 100** (les cristaux texturés se regroupent en un seul lot, contrairement aux anciens losanges dessinés un par un).

## 2. Améliorations visuelles
Capture : `art_tests/nuit_explosions_morts.png` (6 instants de la même explosion ; en dessous, les morts) et `art_tests/nuit_cristaux.png`. Galerie : `vfx_gallery.tscn -- --blasts`.
- **Explosions** : un cœur blanc qui s'éteint vite, des flammes qui gonflent puis rétrécissent (couleur de l'arme vers l'orange), une onde de choc qui s'élargit en s'amincissant, des éclats projetés et de la fumée en fin d'effet. Contour noir comme le reste du jeu.
- **Mort des monstres** : un éclair blanc et un anneau de la taille du monstre, puis 6 morceaux de sa couleur projetés, qui retombent un peu.
- **Cristal de matériau** : image générée dans le style des objets (`art_source/ai/pickups/crystal_2.png`), violette quand plusieurs cristaux ont fusionné.

## 3. Tests au simulateur (vraies parties, 64 au total)
Bot « Zone » : il achète surtout la Zone et les armes de sa famille. Épéiste et Contrebandier, sceaux Cuivre (0) et Astral (5), 4 parties par cas.

| Plafond | Épéiste Cuivre | Épéiste Astral | Contreb. Cuivre | Contreb. Astral |
|---|---|---|---|---|
| +200 % (actuel) | 4/4, PV perdus en fin de partie 58 % | 1/4 | 3/4, 14 % | 2/4 |
| +150 % | 4/4, 76 % | 2/4 | 3/4, 27 % | 1/4 |
| +100 % | 4/4, 67 % | 2/4 | 3/4, 47 % | 1/4 |

Le pourcentage entre parenthèses est la médiane des PV perdus par vague, de la vague 15 à la 19.

- **Un build Zone atteint le plafond, même à +200 %**, dès le sceau Cuivre : 4 Épéistes sur 4 finissent à +200 %.
- **Le plafond change peu les victoires** : les écarts entre 100, 150 et 200 % restent dans le bruit de 4 parties. Un plafond plus bas rend surtout la fin de partie un peu moins confortable avec les bombes du Contrebandier (14 % → 47 % de PV perdus).
- **Pas de coût de calcul visible** des grandes zones : les parties durent autant de temps de calcul quel que soit le plafond.
- Au sceau Astral, les mêmes parties meurent tôt (vagues 4-6), quel que soit le plafond. C'est le tirage de départ, pas la Zone.
- **Recommandation** : garder +200 % si la lisibilité te convient en jeu, sinon passer à +150 %. L'équilibrage ne l'impose pas.

**Mode infini** (bot « joueur correct », sceau Cuivre, jusqu'à la vague 30 au maximum) :

| Perso | Vague atteinte |
|---|---|
| Archer | 25, 26 |
| Mage | 22, 24 |
| Épéiste | 25 (l'autre partie est morte en vague 10, avant l'infini) |
| Contrebandier | 30 et 30 (arrêt du test) |

Depuis les PV ×160 en vague 20, **l'infini est devenu dur** : la plupart des builds meurent entre les vagues 22 et 26 (+25 % de PV et +12 % de dégâts par vague). Session 7, tu le trouvais trop facile (vague 31, 15 000 matériaux). À ressentir en jeu ; si c'est trop dur, baisser `endless_hp_growth` de 0,25 à 0,15 (`data/stages/default.tres`). Rapport HTML : `art_tests/nuit_infini_report.html`.

## Tests
416 tests passent, tous les scripts compilent.

## À décider par le dev
1. Fusionner les branches de la nuit dans `playtest/2026-10-05` pour essayer.
2. Plafond de Zone : +200 % ou +150 %.
3. Difficulté du mode infini.
4. Pantins des 6 autres persos (pas faits cette nuit, pas choisis).
