# Statut du projet — Survivor Game (titre de travail)

> Journal de suivi entre les sessions : état actuel, décisions prises, changements, retours de playtest et prochaines étapes.
> **À lire au début de chaque session, à mettre à jour à la fin.** Les règles de développement sont dans `CLAUDE.md`, le design dans `docs/design/gdd.md`, les décisions techniques détaillées dans `docs/decisions/`.

Dernière mise à jour : 2026-10-03 (session 3)

---

## 1. Où en est-on ?

| | |
|---|---|
| **Phase actuelle** | Phase 5 (boutique façon Brotato) : socle livré → playtest du dev, puis Phase 3 (objets à effets, menus) |
| **Branche de travail** | `develop` (ne jamais commiter sur `main` sans demande explicite) |
| **Dernière version sur `main`** | `00e60be` — Phase 2 (combat + rendu néon) |
| **Tests** | 153/153 (GUT : unitaires, données, parties simulées) |
| **Performance (stress test)** | ~175-184 FPS moyen, min ~130-140 — 500 ennemis, ~1000 projectiles, 6 armes rang IV (mesure 2026-10-03, machine libre ; avant la boutique : ~180 FPS) |

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
- Détails visuels : le titre « Vague X terminée » se devine derrière les cartes de level-up ; projectiles et chiffres figés restent visibles derrière les écrans de fin.
- Outils : l'installation Claude Code Game Studios demande un redémarrage de Claude Code (Python/jq dans le PATH) et les hooks doivent être branchés dans `.claude/settings.json` par le dev.
- Outils : l'exécutable `Godot_v4.7.2-stable_win64_console.exe` ne fonctionne pas seul (on utilise `Godot.exe`). GUT 9.7.1 est disponible (on est en 9.6.1).

---

## 6. Prochaines étapes

1. **Direction artistique (D31) — en attente de validation du dev** : pack RGS_Dev téléchargé dans `assets_src/third_party/rgs_characters/` (CC0 ; 4 persos, 4 ennemis, 1 512 pièces blanches colorables, 3 sols, 3 rochers ; images 2048×2048, perso ≈ 500 px en bas au centre ; animations idle 6, walk 8, hit 3, death 10, roll, jump ; Enemy 3 = chauve-souris `fly` 6 seulement). Proposition faite au dev, à reprendre :
   - Outil de conversion : recadrage sur l'union des cadres d'une animation, réduction à ~128 px, planches de sprites dans `assets/sprites/`.
   - Rendu : un MultiMesh par type d'ennemi avec index d'image par instance (comme ADR 0004), contour néon par shader à la couleur de la menace, sol du pack teinté sombre + grille néon.
   - Attribution proposée : joueur = Char 1 (cheveux bleus) ; grunt = Enemy 1 (diable violet) ; runner = Enemy 3 (chauve-souris) ; shooter = Enemy 2 (ogre vert) ; tank = Enemy 4 (diable rouge) agrandi ; shogun = Enemy 4 géant teinté magenta.
   - Étapes : outil → **capture test d'une horde** à valider → spec courte → intégration.
2. **Dev** : écouter le son en jeu (sons choisis sans écoute, à changer au goût) ; rejouer une run complète (F3) : densité des vagues 10-20, matériaux, panneau de stats (Tab) ; ajuster D30.
3. **Phase 3 — Objets à effets et synergies** (vendus par la boutique), puis **menus** (principal, pause, paramètres avec volumes).
4. Phase 6 (vrai boss), puis 6b (vertical slice + page Steam). Roadmap complète : `docs/design/gdd.md`.

---

## 7. Procédure de session (pour Claude)

- **Début** : lire ce fichier et `CLAUDE.md`, vérifier qu'on est sur `develop` (`git branch --show-current`).
- **Pendant** : toute décision du dev → section 2 ; tout retour de playtest → section 4.
- **Fin** : mettre à jour les sections 1, 3, 5 et 6 et la date en haut, puis commiter sur `develop` si le dev le demande.
