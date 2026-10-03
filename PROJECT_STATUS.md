# Statut du projet — Survivor Game (titre de travail)

> Journal de suivi entre les sessions : état actuel, décisions prises, changements, retours de playtest et prochaines étapes.
> **À lire au début de chaque session, à mettre à jour à la fin.** Les règles de développement sont dans `CLAUDE.md`, le design dans `docs/design/gdd.md`, les décisions techniques détaillées dans `docs/decisions/`.

Dernière mise à jour : 2026-10-03 (session 5)

---

## 1. Où en est-on ?

| | |
|---|---|
| **Phase actuelle** | Passe visuelle (3 chantiers) terminée : 1. sprites animés ✅ · 2. icônes d'armes/objets + armes visibles ✅ · 3. thème des interfaces ✅. B. objets à effets et familles ✅ · C. menus et paramètres ✅ · 6. vrais boss ✅ · 5b. nouveaux ennemis ✅. Suite (D46) : 7 méta-progression → 7b modes → 6b vertical slice ; méta-progression en discussion (`docs/design/meta-progression-proposition.md`) |
| **Branche de travail** | `develop` (ne jamais commiter sur `main` sans demande explicite) |
| **Dernière version sur `main`** | `00e60be` — Phase 2 (combat + rendu néon) |
| **Tests** | 275/275 (GUT : unitaires, données, parties simulées) |
| **Performance (stress test)** | ~100 FPS moyen (pire cas : 650 ennemis, 7 armes rang IV, toutes les familles actives ; ~120 avant les familles). Seuil : ≥ 100 FPS (D37). Mesures isolées : ±15 FPS |
| **Dernier push** | `ca472d9` (session 4) — commits suivants pas encore poussés |

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
| D37 | 2026-10-03 | **Performance : 100 FPS suffisent** | Dev : « même s'il tourne à 100 FPS, ce n'est pas un jeu compétitif ». Seuil du stress test : ≥ 100 FPS moyen (au lieu de 150) |
| D38 | 2026-10-03 | **Rééquilibrage vagues 12-20 : plus de monstres, plus de PV, moins de pouvoir d'achat** | Apparitions fin de partie 24 → 32/s ; PV ×3 → ×8 en vague 20 avec une courbe tardive (×3,4 vague 12, ×5,4 vague 16) — remontée prévue par D24 ; matériaux par XP 60 % → 30 % en vague 20 ; inflation des prix 10 % → 12 % par vague |
| D39 | 2026-10-03 | **Caméra plus proche, arène plus petite (façon Brotato)** | Zoom 1,3 ; arène 3200 → 2400 ; apparition à 950 px (au lieu de 1150, toujours hors écran). Plus de pression, personnages plus lisibles. Réglable dans `data/runs/default.tres` |
| D42 | 2026-10-03 | **Objets à effets et familles d'armes (étape B)** : 4 stats (esquive, vol de vie, chance, récolte), 4 familles à paliers 2/4/6 (lames, armes à feu, énergie, explosif), 6 types d'effets, 13 nouveaux objets (28 au total), objets forts uniques | Choix « reco » du dev. ADR 0012 |
| D41 | 2026-10-03 | **Se sentir submergé (vagues 12-20)** : plafond 500 → 650 ennemis, apparitions fin 32 → 45/s **en paquets** (1 à 12 monstres qui arrivent ensemble d'un côté), hordes en plus vagues 14/16/19, plus de chauves-souris dès la vague 14 ; PV ×8 → ×12 en vague 20 ; **dégâts des ennemis qui montent** (×1,3 vague 10, ×1,8 vague 15, ×2,5 vague 20) ; vitesse inchangée ; build non affaibli | Retour du dev (« je ne bouge plus dès la vague 15-16, je veux être submergé ») et proposition validée. Pas d'optimisation au-delà de 1 000 ennemis (inutile : les monstres meurent avant). Mesure : 650 ennemis ≈ 120 FPS, 800 ≈ 90, 1 200 ≈ 48 |
| D40 | 2026-10-03 | **Thème d'interface « chibi néon »** : contour noir, fond violet nuit, lueur néon ; polices Fredoka + Nunito ; animations discrètes ; tous les écrans | Choix « reco » du dev. Un seul `Theme` construit par `UiTheme`, animations `UiFx`. ADR 0011 |
| D43 | 2026-10-03 | **Anti-boule de neige : matériaux découplés du nombre d'ennemis + plus d'apparitions** | Au-delà de 12 apparitions/s, le taux de matériaux baisse (`material_reference_spawn_rate` = 12, `material_decoupling` = 0,6) : les matériaux par seconde restent ~10-12 des vagues 10 à 20 au lieu de suivre les kills ; `material_rate_last` 0,3 → 0,5 pour compenser. Apparitions fin de partie 45 → 60/s. **Plafond gardé à 650** : 800 mesuré à ~77 FPS au stress test (sous le seuil D37) ; le dev peut le monter s'il accepte ce coût. PV et prix inchangés |
| D44 | 2026-10-03 | **Menus (étape C)** : menu principal animé (Jouer / Paramètres / Quitter), pause complète (Reprendre / Paramètres / Recommencer / Menu principal / Quitter, confirmation avant d'abandonner, stats à côté), paramètres audio + affichage + jeu/accessibilité + langue sauvegardés dans `user://settings.json`, autoloads `Settings` et `SceneRouter` | Choix « reco » du dev. ADR 0013 |
| D45 | 2026-10-03 | **Rééquilibrage global : moins de pouvoir d'achat dès le début, plus d'ennemis plus tôt** | Playtest : « trop facile du début à la fin, je relance et j'achète beaucoup, trop fort dès la vague 10 ». Matériaux par XP 1,0 → 0,5 (début) et 0,5 → 0,35 (fin), découplage dès 8 apparitions/s (exposant 0,7) : ≈ -30 % de matériaux en vague 6, ≈ -55 % dès la vague 10 (estimation). Relance : `1 + floor(vague × 0,75) + max(1, floor(vague × 0,6))` par relance (vague 10 : 8 puis +6, avant 6 puis +5). Niveaux un peu plus lents (exposant XP 1,35 → 1,42). Apparitions 1,5 → 2,5/s au départ, courbe 1,8 → 1,4 (vague 6 : 6,8 → 11,4/s ; vague 10 : 16,7 → 22,7/s). PV plus tôt (courbe 2,0 → 1,6 : ×4,3 en vague 10 au lieu de ×3,5) ; ×12 en vague 20 inchangé. Plafond 650 inchangé |
| D46 | 2026-10-03 | **Méta-progression : recommandations Q1-Q11 validées** | Méta horizontale (déblocages de contenu, pas de bonus de stats permanents) par défis ; persos à règle unique + bonus/malus, arme de départ au choix, difficulté par perso ; ennemis chargeur, kamikaze, pondeur ; 650 max ; mini-boss vague 10 + boss final aléatoire (Shogun d'abord) ; mode infini après victoire. Ordre : 6 → 5b → 7 → 7b → 6b. `docs/design/meta-progression-proposition.md` |
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

- **Passe visuelle, chantier 2 — armes et objets** (spec + plan dans `docs/superpowers/`, ADR 0010) : 21 icônes SVG (6 armes, 15 objets) générées par `tools/icons/make_icons.py`, armes dessinées autour du perso (visée, recul, éclair de bouche, coup de katana, liseré de rang par shader), tirs depuis le canon, icônes en boutique (cartes, armes, objets avec quantité) et dans le HUD. Outils : planche `icon_sheet.tscn`, capture `--shop`. Revue finale : rayon laser qui ratait en bord de portée, tirs à bout portant qui partaient derrière la cible, armes qui ne clignotaient pas avec le joueur — corrigés. 183 tests

- **Gel au passage à la vague suivante corrigé** (grille des ennemis périmée après le nettoyage de fin de vague, interrogée par la visée des armes) ; **flou de mouvement** : la caméra suit au rythme de la physique.
- **Rééquilibrage** (D38) et **caméra/arène** (D39) après le retour du dev.
- **Passe visuelle, chantier 3 — thème des interfaces** (spec + plan dans `docs/superpowers/`, ADR 0011) : `UiTheme` (thème unique, polices Fredoka/Nunito, styles et variations), `UiFx` (apparition, soulèvement, rebond, compteurs), appliqués au HUD, level-up, boutique, fin de vague, game over/victoire, panneau de stats, chiffres de dégâts. Revue finale : grossissement à l'apparition et rebond à l'achat annulés par les conteneurs, police par défaut trop fine — corrigés. 205 tests

- **Étape B — objets à effets et familles d'armes** (spec + plan dans `docs/superpowers/`, ADR 0012) : esquive, vol de vie, chance, récolte ; `ItemEffects` + 6 types d'effets ; 4 familles d'armes avec bonus 2/4/6 ; 13 nouveaux objets avec icônes ; familles affichées en boutique et dans le panneau de stats. Revue finale : une attaque de zone interrompue quand une élimination déclenchait le Réacteur en chaîne — corrigé (explosions en file d'attente). Proposition de méta-progression rédigée (11 questions). 234 tests

### Session 5 — 2026-10-03

- **Panneau de stats** : sous chaque famille, bonus actif (vert) et palier suivant (« À 4 : +10 % Chance de critique, +20 % Dégâts critiques »), lignes repliées pour ne pas élargir le panneau.
- **Équilibrage anti-boule de neige** (D43) : matériaux découplés des apparitions, 60 apparitions/s en vague 20. 236 tests.
- **F5 ne lançait plus le jeu** : un `/` tapé par erreur dans `enemy_manager.gd` (ligne de commentaire) cassait la compilation. Corrigé.
- **Étape C — menus et paramètres** (spec + plan dans `docs/superpowers/`, ADR 0013) : menu principal (scène de démarrage), menu pause (Échap / P / Start), écran de paramètres partagé, bouton « Menu principal » en fin de partie, captures `--menu`, `--pause`, `--settings`. Les tests n'utilisent jamais les paramètres du joueur (crochet GUT). 256 tests
- **Manette : la croix / A ne validait rien dans les menus** : dans Godot 4.7, les actions `ui_accept` / `ui_cancel` par défaut n'ont aucun bouton de manette. Ajout de A/Croix et B/Rond dans l'InputMap du projet + test. 257 tests
- **Manette en boutique : bloqué sur une carte quand les cartes voisines sont vendues** (la recherche automatique de Godot ne saute pas le trou). Boutons Acheter/Verrouiller reliés explicitement d'une carte en vente à la suivante. Manette vue en double (DS4Windows sans HidHide) : réglage côté PC, protection en jeu prévue avec `Platform` (Phase 10). 258 tests
- **Rééquilibrage D45** (moins de matériaux, relance plus chère, plus d'ennemis plus tôt) et **réponses Q1-Q11 validées** (D46).
- **Étape 6 — vrais boss** (spec `docs/superpowers/specs/2026-10-03-boss-design.md`, ADR 0014) : phases selon les PV, 4 motifs d'attaque annoncés (cercle, éventail, ruée, invocation), barre de vie, récompense ; Ronin (mini-boss vague 10, remplace les 2 tireurs élites) et Shogun en 3 phases (vague 20). Capture `--boss=shogun|ronin`. 270 tests
- **Étape 5b — nouveaux ennemis** (spec `docs/superpowers/specs/2026-10-03-nouveaux-ennemis-design.md`) : Chargeur (annonce puis ruée, dès la vague 7), Kamikaze (mèche puis explosion, pas d'XP s'il explose, dès la vague 5), Pondeuse (appelle 3 coureurs toutes les 4 s, dès la vague 9), gérés dans la boucle d'`EnemyManager`. Stress test 108-110 FPS. 275 tests

---

## 4. Retours du dev (playtests)

| Date | Version | Retour | Suite donnée |
|---|---|---|---|
| 2026-10-02 | Phase 1 | « Jouabilité correcte, mais difficile à jauger avec une seule arme ; ça devient compliqué avec le temps » | Phase 2 : armes multiples et niveaux d'armes |
| 2026-10-02 | Phase 2 | « Les chiffres de dégâts sont un peu trop petits et pas assez impactants » ; sinon OK | Chiffres plus grands (30/48), police grasse, effet « pop », critiques jaunes avec secousse (sans « ! », retiré à la demande du dev), taille selon le montant |
| 2026-10-02 | Phase 4 | « Arrivé à la vague 20, pas de boss. J'ai survécu en fuyant, pas en écrasant les mobs ; à la fin du chrono il en restait beaucoup. » Fuite dès la vague 10 | Boss provisoire (D23), densité réduite (D24), compteur F3 pour mesurer. Le dev accepte que la puissance viendra de la boutique |
| 2026-10-03 | Après étape B | « Le panneau de stats liste les familles (énergie, armes à feu, explosif, lames) mais ne dit pas quels bonus elles donnent. » « Vagues 12-20 : plus d'ennemis, mais le perso évolue toujours aussi vite : plus je tue, plus j'ai de matériaux et de pouvoir d'achat. Mettre encore plus d'ennemis, un peu plus de PV, limiter un tout petit peu le pouvoir d'achat. J'aime avoir des stats cheatées, mais alors il faut plus de PV ou d'ennemis. Le plafond de 650 n'est jamais atteint : je les tue bien avant. » | **À faire en début de prochaine session** (voir §6, point 1) |
| 2026-10-03 | Après chantier 3 | « De la vague 14 à 20 on devient exponentiellement trop fort, je ne bouge presque plus dès la 15-16. Plus de mobs, un peu plus de PV, se sentir submergé, beaucoup de chiffres. » « Avec beaucoup d'explosions le tremblement rend le jeu flou. » | D41 ; tremblement lissé (bruit fluide, explosions plafonnées) |
| 2026-10-03 | Chantiers visuels 1-2 | « Dès la manche 12-14 on est trop puissant ; à partir de la vague 15-16 je n'ai plus besoin de bouger. Plus de mobs, moins de pouvoir d'achat. » « 100 FPS, ce n'est pas un jeu compétitif. » Caméra : un peu plus zoomée, arène plus petite (comme Brotato) | D37, D38, D39 |
| 2026-10-03 | Phase 5 | « Le bazooka avec plus de portée explose après une certaine distance, pas au contact. » « Voir mes stats (dégâts, vitesse, projectiles). » « Dès la vague 10 le build est trop fort : plus d'ennemis, pas moins de puissance ; trop de matériaux en vagues 15-20. » « Laisse tomber la 3D. » | Bug de portée corrigé ; panneau de stats ; D30 ; D29 |

---

## 5. Limites connues / dette

- **Paramètres** : pas de remappage des touches ni de choix de résolution (Phase 9). Le titre du menu est le titre de travail (`GAME_TITLE`).
- **Audio provisoire** : sons choisis sans écoute (Kenney), à remplacer au goût du dev.
- **Équilibrage = premières estimations** (dégâts, courbe d'XP, poids des cartes, apparition des ennemis, prix, chances de rang, objets).
- **Boutique, socle seulement** : objets sans effets spéciaux ni synergies, pas de caisses lâchées par les élites, pas de stat « récolte » ni « chance », visuel des matériaux provisoire (gemmes d'XP).
- Boss : sprites réutilisés (Shogun = rôdeur teinté, Ronin = colosse teinté) ; un seul boss final pour l'instant (`enemy_choices`).
- Valeurs des vagues = premières estimations (durées, densité, PV, vagues spéciales) : à régler après playtest.
- FPS minimum au stress test ~10 % plus bas qu'avant les vagues (moyenne inchangée) : à surveiller.
- Sprites provisoires : pas d'animation de coup reçu ni de mort (flash blanc + effet existant) ; le Shogun réutilise le diable violet ; tailles réglées à l'œil sur captures.
- Détails visuels : le titre « Vague X terminée » se devine derrière les cartes de level-up ; projectiles et chiffres figés restent visibles derrière les écrans de fin.
- Outils : l'installation Claude Code Game Studios demande un redémarrage de Claude Code (Python/jq dans le PATH) et les hooks doivent être branchés dans `.claude/settings.json` par le dev.
- Outils : l'exécutable `Godot_v4.7.2-stable_win64_console.exe` ne fonctionne pas seul (on utilise `Godot.exe`). GUT 9.7.1 est disponible (on est en 9.6.1).

---

## 6. Prochaines étapes

0. **Dev : rejouer une run complète** (F3 pour le compteur) pour juger D43 : matériaux des vagues 12-20, densité, panneau des familles (Tab). Leviers restants si besoin : PV fin de partie ×12 → ×16, inflation des prix 12 % → 15 %, plafond 650 → 800 (~77 FPS en pire cas).
1. **Dev : valider le chantier 1 en jeu** (sprites, tailles, sol, Shogun) ; lancer le jeu ou la galerie `vfx_gallery.tscn`. Réglages rapides : `SPRITE_HEIGHT_PER_RADIUS` (`enemy.gd`, `player.gd`), `sprite_scale` / `sprite_tint` dans `data/enemies/`, `FLOOR_TINT` (`arena.gd`), halo dans `tools/sprites/bake_sprites.gd`.
2. **Dev : valider le chantier 2** (icônes, armes autour du perso, boutique). Question ouverte : **zoom de la caméra** (aujourd'hui 1 : le perso fait ~60 px en 1080p, plus petit que dans Brotato ; zoomer agrandit tout mais montre moins d'arène). Re-mesurer le stress test sur une machine au repos (ADR 0010).
3. **Dev : répondre aux 11 questions de `docs/design/meta-progression-proposition.md`** (méta-progression, persos, difficultés, ennemis, boss, mode infini, ordre des étapes), puis planifier les étapes 6/7/8.
4. **D.** playtest (nouveaux objets, familles, équilibrage D41/D43) ; **dev : tester les menus** (Échap en partie, paramètres, plein écran, langue, manette).
4. **Dev** : écouter le son en jeu (sons choisis sans écoute, à changer au goût) ; rejouer une run complète (F3) : densité des vagues 10-20, matériaux, panneau de stats (Tab) ; ajuster D30.
6. Phase 6 (vrai boss), puis 6b (vertical slice + page Steam). Roadmap complète : `docs/design/gdd.md`.

---

## 7. Procédure de session (pour Claude)

- **Début** : lire ce fichier et `CLAUDE.md`, vérifier qu'on est sur `develop` (`git branch --show-current`).
- **Pendant** : toute décision du dev → section 2 ; tout retour de playtest → section 4.
- **Fin** : mettre à jour les sections 1, 3, 5 et 6 et la date en haut, puis commiter sur `develop` si le dev le demande.
