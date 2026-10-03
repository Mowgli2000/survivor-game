# Statut du projet — Survivor Game (titre de travail)

> Journal de suivi entre les sessions : état actuel, décisions prises, changements, retours de playtest et prochaines étapes.
> **À lire au début de chaque session, à mettre à jour à la fin.** Les règles de développement sont dans `CLAUDE.md`, le design dans `docs/design/gdd.md`, les décisions techniques détaillées dans `docs/decisions/`.

Dernière mise à jour : 2026-10-03 (session 4)

---

## 1. Où en est-on ?

| | |
|---|---|
| **Phase actuelle** | Passe visuelle (3 chantiers) : 1. sprites animés ✅ · 2. icônes d'armes/objets + armes visibles autour du joueur ✅ · 3. thème des interfaces. Ensuite Phase 3 (objets à effets), menus, playtest |
| **Branche de travail** | `develop` (ne jamais commiter sur `main` sans demande explicite) |
| **Dernière version sur `main`** | `00e60be` — Phase 2 (combat + rendu néon) |
| **Tests** | 181/181 (GUT : unitaires, données, parties simulées) |
| **Performance (stress test)** | ~163 FPS moyen (formes néon : ~176, mesuré en alterné) — 500 ennemis, ~1000 projectiles, 6 armes rang IV. Mesures isolées : ±15 FPS (ADR 0009) |

**Emplacements**
- Projet local : `C:\Users\rapha\Projects\survivor-game` (ouvrir `project.godot` dans Godot)
- GitHub : https://github.com/Mowgli2000/survivor-game (branches `main` et `develop`)
- Godot utilisé : `C:\Program Files\Godot\Godot.exe` (4.7.2 stable)

---

## 2. Décisions prises

| # | Date | Décision | Détail / raison |
|---|---|---|---|
| D1 | 2026-10-02 | **Godot 4.7.2, GDScript typé, renderer Compatibility** | Simple, itération rapide, compatible avec un maximum de PC et le Steam Deck. ADR 0001 |
| D2 | 2026-10-02 | **Structure de run : arène bornée + vagues chronométrées + boutique entre les vagues** | Rythme clair, la boutique devient centrale (différenciateur) |
| D3 | 2026-10-02 | **Visée 100 % automatique** | Le joueur ne gère que le déplacement ; la profondeur vient du build, du positionnement et de l'économie |
| D4 | 2026-10-02 | **Projet hors OneDrive** (`C:\Users\rapha\Projects\`) | OneDrive casse souvent Git et le cache Godot |
| D5 | 2026-10-02 | **Ennemis/projectiles gérés en lot + grille spatiale + pooling** | Performance avec des centaines d'entités. ADR 0002 |
| D6 | 2026-10-02 | **Contenu en Resources `.tres`, sauvegardes en JSON** | Ajouter du contenu sans toucher au code ; saves sûres et versionnées. ADR 0003 |
| D7 | 2026-10-02 | **Projectiles rendus en un seul appel de dessin (MultiMesh)** | 41 → 220 FPS au stress test. ADR 0004 |
| D8 | 2026-10-02 | **Production visuelle** : Claude produit formes, SVG, effets et animations procédurales ; les images (pixel art, illustrations, concept art) viennent d'outils externes (IA d'image, Aseprite, Blender, packs, freelance) | Limite de Claude : pas d'images matricielles. Divulgation IA obligatoire sur Steam si utilisée |
| D9 | 2026-10-02 | **Thème de travail : cyber-samouraï / ninja néon** | Lames futuristes **et** armes high-tech (pistolets laser, mitraillettes, bazookas) **et** armes imaginaires. Une couleur néon forte par arme pour la lisibilité |
| D10 | 2026-10-02 | **Les armes actuelles sont provisoires** | Priorité au *système* d'armes ; il y aura beaucoup d'armes à la fin |
| D11 | 2026-10-02 | **Dégâts centralisés dans `EnemyManager`, une seule couche d'effets, sprites ennemis précalculés** | Règles de combat à un seul endroit ; 49 → 204 FPS. ADR 0005 |
| D12 | 2026-10-02 | **Filtrage des textures en linéaire** | Adapté au style néon et aux textures qui tournent |
| D13 | 2026-10-02 | **Git : travail sur `develop`, `main` = versions validées sur demande** | Demande du dev |
| D14 | 2026-10-02 | **Vagues (Phase 4) avant les objets (Phase 3)** | Les vagues donnent la structure du jeu ; les objets seront équilibrés sur le vrai rythme. Demande du dev après playtest (partie infinie de 15+ min) |
| D15 | 2026-10-02 | **Objets : le level-up donne des stats, la boutique vend des objets** | Appliqué tel quel par D25 (la boutique arrive avant les objets riches) |
| D16 | 2026-10-02 | **Run = 20 vagues, 20 s → 60 s** | Format éprouvé avec boutique ; valeurs dans `data/stages/default.tres` |
| D17 | 2026-10-02 | **Level-up différé à la fin de la vague** | Vagues fluides ; toutes les décisions de build au même moment (boutique plus tard). ADR 0006 |
| D18 | 2026-10-02 | **PV remis au max entre les vagues** | Chaque vague est un défi lisible ; réglable (`heal_between_waves`) |
| D19 | 2026-10-02 | **Élite = ennemi existant renforcé** | PV ×5, XP ×10, taille ×1,6, contour doré ; pas de nouvel art |
| D20 | 2026-10-02 | **Fin du chrono : ennemis restants disparaissent, gemmes ramassées** | Durée de vague fixe, fin nette ; pas d'XP pour les disparus |
| D21 | 2026-10-02 | **Victoire après la vague 20** | Remplacé par D23 (boss provisoire) |
| D22 | 2026-10-02 | **Suivre au maximum la logique de Brotato** | Demande du dev après playtest. Durées de vague à la Brotato : 20 s +5 s par vague jusqu'à 60 s, vague 20 = 90 s (`duration_step`, `final_wave_duration`) |
| D23 | 2026-10-02 | **Boss provisoire « Shogun » en vague 20** | Ennemi à part (`boss = true`, octogone magenta, 900 PV de base ×3). Comme Brotato : le tuer gagne la partie tout de suite ; survivre au chrono gagne aussi. Vrai boss en Phase 6 |
| D24 | 2026-10-02 | **Densité réduite en attendant boutique et objets** | Apparitions 1,5 → 10/s (au lieu de 20), PV ×1 → ×3 (au lieu de ×5). À remonter quand la boutique donnera de la puissance |
| D25 | 2026-10-02 | **Boutique (Phase 5) avant les objets riches et les menus** | La puissance vient de la boutique, comme Brotato. Matériaux = XP + monnaie (départ 30). ADR 0007 |
| D26 | 2026-10-02 | **Armes en double, 4 rangs (I gris, II bleu, III violet, IV rouge), fusion** | 6 emplacements ; 2 armes identiques de même rang → rang supérieur ; achat avec emplacements pleins = fusion directe ; vente à 25 % |
| D27 | 2026-10-02 | **15 objets de stats simples** (bonus/malus, rang fixe) | Effets spéciaux et synergies plus tard (Phase 3) |
| D28 | 2026-10-02 | **Level-up = stats seulement, 4 cartes à rang, relance payante** | Bonus ×1 / ×1,6 / ×2,4 / ×3,2 selon le rang ; même coût de relance que la boutique |
| D29 | 2026-10-03 | **On reste en 2D** (abandon du prototype 3D/2.5D) | Décision du dev : la 2D convient au genre et facilitera une version mobile |
| D30 | 2026-10-03 | **Plus d'ennemis en fin de partie, moins de matériaux, builds intacts** | Apparitions en courbe (≈3/s vague 5, 7/s vague 10, 15/s vague 15, 24/s vague 20), plafond 500 ; matériaux par XP 100 % → 60 % ; PV des ennemis inchangés. Objectif : beaucoup de monstres, beaucoup de chiffres |
| D31 | 2026-10-03 | **Direction artistique : chibi façon Dofus × néon, assets gratuits, vue de dessus** | Personnages vectoriels chibi (pack CC0 RGS_Dev en premier test), néon ajouté par le jeu (contour lumineux, une couleur par menace). Packs bruts dans `assets_src/` (ignoré par git) |
| D32 | 2026-10-03 | **Audio : autoload `Audio`, sons Kenney CC0, musique synthwave CC0** | Sons de tir par arme, impacts, morts, explosions, UI, jingles. Anti-saturation. ADR 0008 |
| D33 | 2026-10-03 | **Passe visuelle en 3 chantiers, avant B/C/D** : 1. sprites animés, 2. icônes armes/objets + armes visibles autour du perso (façon Brotato), 3. thème de toutes les interfaces | Demande du dev : « un beau visuel de toutes les interfaces ». Icônes = SVG faits par Claude dans le style du pack (remplaçables plus tard) |
| D34 | 2026-10-03 | **Rendu coloré, pas sombre** : chibi en couleur + halo néon, sol bleu-violet moyen | Choix du dev (option A) : « je ne veux pas un jeu trop sombre ». Attribution et design des sprites provisoires |
| D35 | 2026-10-03 | **Sprites animés : atlas précalculé, animation pilotée par les managers** | Outil `tools/bake_sprites.ps1`, `SpriteSheet` `.tres`, redessin au changement d'image, y-sort. Coût ~7 % de FPS. ADR 0009 |
| D36 | 2026-10-03 | **Armes visibles façon Brotato + icônes** : positions fixes en cercle, armes petites, icônes d'objets dans le même style, cadre de rang en interface + liseré en jeu | Choix « reco » du dev. Les tirs partent du canon ; la cible reste choisie depuis le centre (pas de rééquilibrage). ADR 0010 |

### Décisions volontairement reportées
| Sujet | Quand | Options / notes |
|---|---|---|
| Nom du jeu et univers détaillé | Avant la page Steam | — |
| Direction artistique définitive | Fin Phase 3 | Piste actuelle : silhouettes sombres + contours néon (produisible en grande partie par Claude) |
| Design final de la boutique | Phase 5 | 1. Boutique classique entre vagues (socle) · 2. Économie à risque (intérêts sur l'or) · 3. Stock influencé par les ennemis tués · 4. Marchand pendant la vague. Reco : 1 comme base, prototyper 2+3 |
| Forme de la méta-progression | Phase 7 | Préférer débloquer du contenu plutôt que des bonus de stats permanents |

---

## 3. Historique des changements

### Session 1 — 2026-10-02

**Phase 0 — Setup** (`e4a735e`)
- Projet Godot, InputMap clavier + manette (touches physiques → ZQSD/WASD automatique), FR/EN, autoload `ContentDB`
- Tests GUT + outils `tools/run_tests.ps1` et `tools/check_scripts.ps1`, export Windows validé
- `CLAUDE.md`, 7 skills Claude Code (`.claude/skills/`), GDD, ADR 0001 à 0003

**Phase 1 — Prototype jouable** (`0fe2585`)
- Déplacement, 1 arme auto (Pulsar), 2 ennemis, dégâts au contact, mort + écran Game Over, gemmes d'XP avec aimant, level-up avec 3 choix, spawn croissant, HUD
- Outils : stress test (`src/debug/stress_test.tscn`), captures d'écran automatiques (`src/debug/capture.tscn`), overlay debug (F3)

**Phase 2 — Combat** (`00e60be`)
- 6 armes à 5 niveaux : Pulsar, katana à plasma, pistolet laser, shuriken, mitraillette, bazooka
- Level-up : mélange nouvelles armes (6 emplacements max) / niveaux d'armes / stats
- Statuts : brûlure, ralentissement, électrocution en chaîne
- Ennemis : Tireur (à distance) et Colosse (blindé)
- Rendu néon, chiffres de dégâts, tremblement d'écran, galerie d'effets (`src/debug/vfx_gallery.tscn`)
- Création de la branche `develop`

---

### Session 2 — 2026-10-02

- **Chiffres de dégâts** plus grands et plus impactants (retour du dev) : `2378b06`
- **Phase 4 — Vagues** (avancée avant la Phase 3, D14) : `StageData` + `WaveEvent`, `WaveDirector`, spawn par vague, élites dorées, nettoyage et collecte en fin de vague, level-up différé, écran inter-vague, victoire, HUD vague + chrono. Spec et plan dans `docs/superpowers/`, ADR 0006
- Correction : l'écran de level-up réactivait des cartes déjà supprimées quand on enchaînait les choix très vite
- Outils : installation de Python 3.12, jq et des fichiers manquants de Claude Code Game Studios (hooks, registres, docs moteur)
- **Après playtest Phase 4** : compteur de vague dans l'overlay F3 (tués / apparus, apparitions/s, PV) + une ligne `[wave N]` par vague dans la console ; durées de vague à la Brotato ; densité réduite (D24) ; boss provisoire Shogun (D23)
- **Phase 5 avancée — Boutique façon Brotato** (spec + plan dans `docs/superpowers/`, ADR 0007) : matériaux, armes à 4 rangs en double avec fusion, 15 objets de stats, boutique entre les vagues (4 emplacements, relance, verrouillage, vente, fusion), level-up à 4 cartes à rang avec relance payante. 136 tests
- **Après playtest Phase 5** (2026-10-03) : correction du bazooka (la portée allongeait la visée mais pas le vol des projectiles : explosions dans le vide), panneau de stats (boutique + Tab en jeu), courbe d'apparition et taux de matériaux (D30), focus clavier/manette de la boutique corrigé (plus de « Vague suivante » par accident). 148 tests
- **Audio** (ADR 0008) : musique en boucle, son de tir par arme, impacts, morts, explosions, ramassages, sons de boutique et de level-up, jingles de vague, victoire et défaite. 153 tests

---

### Session 4 — 2026-10-03

- **Passe visuelle, chantier 1 — sprites animés** (spec + plan dans `docs/superpowers/`, ADR 0009) : outil de conversion du pack RGS_Dev (recadrage, réduction, halo néon, variantes élite dorées, atlas unique), `SpriteSheet` / `SpriteAnimator`, ennemis et joueur animés (idle/marche, orientés vers le joueur / selon le déplacement), Shogun = diable violet géant teinté magenta, tri en profondeur (y-sort), sol texturé bleu-violet. Galerie mise à jour (ennemis animés, brûlés, élites). Stress test : nouvelle ligne « draw calls ». Revue finale : correction du retournement vers la gauche (sprite décalé de sa zone de collision), outil de conversion qui échoue proprement. 168 tests

- **Passe visuelle, chantier 2 — armes et objets** (spec + plan dans `docs/superpowers/`, ADR 0010) : 21 icônes SVG (6 armes, 15 objets) générées par `tools/icons/make_icons.py`, armes dessinées autour du perso (visée, recul, éclair de bouche, coup de katana, liseré de rang par shader), tirs depuis le canon, icônes en boutique (cartes, armes, objets avec quantité) et dans le HUD. Outils : planche `icon_sheet.tscn`, capture `--shop`. 181 tests

---

## 4. Retours du dev (playtests)

| Date | Version | Retour | Suite donnée |
|---|---|---|---|
| 2026-10-02 | Phase 1 | « Jouabilité correcte, mais difficile à jauger avec une seule arme ; ça devient compliqué avec le temps » | Phase 2 : armes multiples et niveaux d'armes |
| 2026-10-02 | Phase 2 | « Les chiffres de dégâts sont un peu trop petits et pas assez impactants » ; sinon OK | Chiffres plus grands (30/48), police grasse, effet « pop », critiques jaunes avec secousse (sans « ! », retiré à la demande du dev), taille selon le montant |
| 2026-10-02 | Phase 4 | « Arrivé à la vague 20, pas de boss. J'ai survécu en fuyant, pas en écrasant les mobs ; à la fin du chrono il en restait beaucoup. » Fuite dès la vague 10 | Boss provisoire (D23), densité réduite (D24), compteur F3 pour mesurer. Le dev accepte que la puissance viendra de la boutique |
| 2026-10-03 | Phase 5 | « Le bazooka avec plus de portée explose après une certaine distance, pas au contact. » « Voir mes stats (dégâts, vitesse, projectiles). » « Dès la vague 10 le build est trop fort : plus d'ennemis, pas moins de puissance ; trop de matériaux en vagues 15-20. » « Laisse tomber la 3D. » | Bug de portée corrigé ; panneau de stats ; D30 ; D29 |

---

## 5. Limites connues / dette

- **Pas de menu pause** : Échap ne fait rien pour l'instant (prévu avec les menus, Phase 3).
- **Pas de menu de paramètres** : les options « tremblement d'écran » et « chiffres de dégâts » existent dans le code, sans interface.
- **Audio provisoire** : sons choisis sans écoute (Kenney), à remplacer au goût du dev ; pas encore de réglage de volume (menu paramètres).
- **Équilibrage = premières estimations** (dégâts, courbe d'XP, poids des cartes, apparition des ennemis, prix, chances de rang, objets).
- **Boutique, socle seulement** : objets sans effets spéciaux ni synergies, pas de caisses lâchées par les élites, pas de stat « récolte » ni « chance », visuel des matériaux provisoire (gemmes d'XP).
- Boss provisoire seulement : pas de barre de vie de boss, pas d'attaque spéciale, même taille qu'un Colosse élite (rayon max de la grille : 48).
- Valeurs des vagues = premières estimations (durées, densité, PV, vagues spéciales) : à régler après playtest.
- FPS minimum au stress test ~10 % plus bas qu'avant les vagues (moyenne inchangée) : à surveiller.
- Sprites provisoires : pas d'animation de coup reçu ni de mort (flash blanc + effet existant) ; le Shogun réutilise le diable violet ; tailles réglées à l'œil sur captures.
- Détails visuels : le titre « Vague X terminée » se devine derrière les cartes de level-up ; projectiles et chiffres figés restent visibles derrière les écrans de fin.
- Outils : l'installation Claude Code Game Studios demande un redémarrage de Claude Code (Python/jq dans le PATH) et les hooks doivent être branchés dans `.claude/settings.json` par le dev.
- Outils : l'exécutable `Godot_v4.7.2-stable_win64_console.exe` ne fonctionne pas seul (on utilise `Godot.exe`). GUT 9.7.1 est disponible (on est en 9.6.1).

---

## 6. Prochaines étapes

1. **Dev : valider le chantier 1 en jeu** (sprites, tailles, sol, Shogun) ; lancer le jeu ou la galerie `vfx_gallery.tscn`. Réglages rapides : `SPRITE_HEIGHT_PER_RADIUS` (`enemy.gd`, `player.gd`), `sprite_scale` / `sprite_tint` dans `data/enemies/`, `FLOOR_TINT` (`arena.gd`), halo dans `tools/sprites/bake_sprites.gd`.
2. **Dev : valider le chantier 2** (icônes, armes autour du perso, boutique). Question ouverte : **zoom de la caméra** (aujourd'hui 1 : le perso fait ~60 px en 1080p, plus petit que dans Brotato ; zoomer agrandit tout mais montre moins d'arène). Re-mesurer le stress test sur une machine au repos (ADR 0010).
3. **Chantier 3 — thème des interfaces** (`/art-bible` puis un `Theme` Godot commun : police, panneaux, boutons, cadres de rang, focus manette) appliqué à tous les écrans.
4. **Dev** : écouter le son en jeu (sons choisis sans écoute, à changer au goût) ; rejouer une run complète (F3) : densité des vagues 10-20, matériaux, panneau de stats (Tab) ; ajuster D30.
5. **Phase 3 — Objets à effets et synergies** (vendus par la boutique), puis **menus** (principal, pause, paramètres avec volumes).
6. Phase 6 (vrai boss), puis 6b (vertical slice + page Steam). Roadmap complète : `docs/design/gdd.md`.

---

## 7. Procédure de session (pour Claude)

- **Début** : lire ce fichier et `CLAUDE.md`, vérifier qu'on est sur `develop` (`git branch --show-current`).
- **Pendant** : toute décision du dev → section 2 ; tout retour de playtest → section 4.
- **Fin** : mettre à jour les sections 1, 3, 5 et 6 et la date en haut, puis commiter sur `develop` si le dev le demande.
