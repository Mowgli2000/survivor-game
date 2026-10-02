# GDD — Survivor Game (titre de travail)

Document vivant. Les décisions d'architecture sont dans `docs/decisions/`, les règles de dev dans `CLAUDE.md`.

## Vision
Survivor-like / roguelite 2D vue de dessus, PC/Steam. Le joueur ne contrôle que le déplacement ; les armes tirent seules. Une run = suite de vagues chronométrées dans une arène bornée, entrecoupées d'une **boutique** qui est le cœur des décisions de build. Identité propre : ne pas copier Brotato / Vampire Survivors.

Piliers : progression constante · décisions fréquentes · sensation de puissance · synergies · risque/récompense · rejouabilité.

Boucle : combat → ressources → boutique/choix → améliorations → build → combat plus dur → boss/événement → récompense → nouvelle phase.

## MVP — prototype jouable minimal

Boucle : **Player → Mouvement → Ennemis → Auto-attaque → Dégâts → Mort → XP → Level-up**.

Contenu exact :
- 1 personnage (cercle/forme placeholder), déplacement 8 directions clavier + stick, caméra qui suit, arène bornée.
- 1 arme : tire automatiquement un projectile vers l'ennemi le plus proche (cadence, dégâts, vitesse, pénétration depuis `WeaponData`).
- 2 ennemis (`.tres`) : basique (poursuit), rapide (fragile). Dégâts au contact, flash blanc au hit, knockback léger.
- PV joueur + invincibilité courte après coup ; mort → écran "Game Over" (Rejouer).
- Gemmes d'XP au sol, aimant de ramassage, barre d'XP.
- Level-up : pause, 3 choix tirés d'un pool de ~6 améliorations de stats (`UpgradeData`), application via `StatBlock`.
- Spawn qui s'intensifie avec le temps (pas encore de vagues).
- HUD : PV, XP, niveau, timer. Textes FR/EN.
- Systèmes poolés + `SpatialGrid` + scène stress test (500 ennemis) + overlay debug.
- Tests : StatBlock, CombatMath, SpatialGrid, ObjectPool, validation des données, smoke test.

Hors MVP : armes multiples, items, boutique, vagues, élites, boss, menus, sauvegarde, audio, vrai art.

Critère de réussite : 5 minutes jouables sans bug, 60 FPS avec 500 ennemis, tests verts, "est-ce que c'est déjà un peu fun à bouger/tirer ?".

---

## Roadmap

| Phase | Contenu | Sortie / critère |
|---|---|---|
| **0 Setup** | Dossier, Git, project.godot (InputMap, renderer, locales, stretch), .gitignore/.gitattributes, GUT, CLAUDE.md, 7 skills, scripts tests, GDD squelette, ADRs initiaux, **test d'export Windows** (valider la chaîne de build tôt). | ✅ Terminée. |
| **1 Prototype** | MVP ci-dessus. | ✅ Terminée — 220 FPS avec 500 ennemis + 1000 projectiles (ADR 0004). |
| **2 Core combat** | 4-6 comportements d'armes, critiques, statuts (brûlure, ralenti), ennemis à distance/tanks, juice (shake, hit-stop, nombres), Audio + EventBus. | ✅ Terminée — 6 armes (Pulsar, katana, pistolet laser, shuriken, mitraillette, bazooka) à 5 niveaux, brûlure/ralentissement/électrocution, tireur + colosse, rendu néon, ~200 FPS (ADR 0005). |
| **3 Progression in-run** *(après la Phase 4, D14)* | Items passifs, modificateurs, raretés, tags/synergies, hooks d'effets, niveaux d'armes, menu principal minimal, Settings. | 20+ items, builds distincts possibles. |
| **4 Waves** *(avancée avant la Phase 3, D14)* | `StageData`, vagues chronométrées, scaling, élites, événements. | ✅ Terminée — 20 vagues (20 → 60 s), élites dorées, 6 vagues spéciales, level-up différé, soin entre vagues, victoire après la vague 20 (ADR 0006). |
| **5 Shop** *(avancée avant la Phase 3, D25)* | Logique pure + UI : stock pondéré, reroll, lock, vente/recyclage, économie ; **prototyper 2 variantes** de différenciation (voir ci-dessous). | ✅ Socle Brotato livré (ADR 0007) : matériaux, armes à 4 rangs en double avec fusion, 15 objets de stats, relance, verrouillage, level-up à rang. Variantes différenciantes à prototyper après playtest. |
| **6 Boss** | Système de phases/patterns data-driven, boss bar, récompenses ; 1er boss. | Run complète début→boss→victoire. |
| **6b Vertical slice + page Steam** *(ajout)* | 1 map, 3 persos, ~10 armes, ~30 items, art direction choisie appliquée, trailer brut. Ouvrir la page Steam (les wishlists prennent des mois). | Page "Coming Soon" en ligne. |
| **7 Méta-progression** | SaveService (JSON versionné, migrations), déblocages, écran de progression. | Save robuste testée. |
| **8 Contenu** | Persos, armes, items, ennemis, maps, défis. Pipeline d'assets IA cohérent. | Volume cible atteint. |
| **9 Polish** | UI/UX complète, audio/musique, VFX, accessibilité, paramètres complets, rebinding, localisation finale. | — |
| **10 Steam** | Platform/GodotSteam, succès, stats, Cloud, overlay, Steam Deck. | Build Steam fonctionnelle sur branche privée. |
| **11 Playtest / Démo** | Démo publique (Steam Next Fest idéalement), télémétrie légère optionnelle, équilibrage. | — |
| **12 Release** | Crash reporting, versioning, checklist, trailer final, lancement. | — |

### Options pour une boutique différenciante (à prototyper Phase 5, pas à décider maintenant)
1. **Boutique entre vagues classique** (base sûre, proche Brotato) — référence de comparaison.
2. **Économie à risque** : l'or non dépensé rapporte des intérêts / augmente la difficulté et la qualité du stock → vrai dilemme "dépenser vs investir".
3. **Stock influencé par le combat** : les ennemis tués laissent des "marques/tags" qui orientent ce que la boutique propose → le combat pilote le build.
4. **Marchand dans l'arène** : boutique accessible pendant la vague, le temps ne s'arrête pas → risque/récompense.
Recommandation : implémenter 1 comme socle (l'architecture supporte les 4), puis tester 2+3 combinées, qui sont les plus originales et peu coûteuses.

### Directions artistiques possibles (à choisir avant fin Phase 3 ; le gameplay est fait en placeholders d'ici là)
1. **Pixel art basse résolution** (24-32 px) — peu coûteux, lisible, outils IA dédiés ; mais marché saturé, identité plus dure.
2. **Silhouettes à fort contraste** (ennemis sombres, accents néon/couleur unique par menace) — ultra lisible en horde, très peu cher, distinctif.
3. **Vectoriel "sticker" épais** (formes simples, contours forts) — rapide à produire, mais risque de ressembler à Brotato.
4. **3D low-poly pré-rendue en sprites** — rendu riche, animations faciles via Blender, pipeline plus technique.
5. **2D peinte HD générée par IA** — attractif en capture, mais cohérence et animation difficiles → déconseillé pour des centaines d'ennemis.
Recommandation : 2 ou 1, testées sur une capture d'écran "horde" avant engagement. Seul élément verrouillé maintenant : **2D vue de dessus**.

---

### Production visuelle — qui fait quoi
- **Claude peut produire directement** (texte/code) : formes et effets procéduraux (`_draw`, shaders, particules, tweens), **SVG** vectoriels importés par Godot, animations procédurales (squash/stretch, rebond, flash, rotation, dissolve), arènes construites en code ou TileMap à partir de tuiles existantes, UI/thème, feedback/juice, scripts d'import/découpe de sprite sheets, guides de style et prompts pour outils d'image IA.
- **Claude ne peut pas produire** : images matricielles (PNG pixel art, illustrations), animations image par image, concept art, musique/sons enregistrés.
- **Sources pour ces assets** : outils IA d'image (PixelLab, Retro Diffusion, Scenario, Midjourney…) + retouche (Aseprite/Krita), Blender pour du pré-rendu 3D, packs d'assets (Kenney CC0, itch.io), ou artiste freelance. Divulgation IA sur Steam si utilisée.
- **Conséquence stratégique** : une DA géométrique/vectorielle (silhouettes, néon, formes fortes) peut être produite presque entièrement par Claude → coût et risque de cohérence minimaux. Une DA pixel art/illustrée exige un pipeline d'assets externe.
- **Phase 1 inchangée** : placeholders géométriques générés en code, remplaçables sans toucher à la logique (visuel séparé des données/comportements).

## Risques principaux

1. **Scope creep** (le plus grand risque d'un solo dev) → MVP minuscule, phases avec critères de sortie.
2. **Perf GDScript avec des milliers d'entités** → architecture en lot + stress test dès Phase 1 ; plan B : MultiMesh, puis C#/GDExtension pour un seul hot-path.
3. **Boutique pas assez différenciante** → prototyper plusieurs variantes tôt (Phase 5) avant la production de contenu.
4. **Cohérence des assets IA** + **divulgation IA obligatoire sur Steam** → style choisi pour être reproductible (palette fixe, gabarits), divulgation prévue.
5. **Compatibilité GodotSteam / Godot 4.7** → vérifier en Phase 0 qu'une version compatible existe ; ne pas changer de version de Godot en cours de route sans raison.
6. **Fichiers `.tscn` édités par l'IA** → peuvent casser des scènes ; scènes simples, vérification headless, commits fréquents.
7. **Sauvegardes corrompues / migration** → JSON versionné, écriture atomique, backup, tests.
8. **Équilibrage** → valeurs en données + simulations headless.
9. **Marketing** : un jeu Steam sans wishlists échoue → page Steam dès la vertical slice, démo Next Fest.
10. **Navigation manette de l'UI** souvent oubliée → exigée dès le premier écran.

---

## Décisions prises
1. Langage : **GDScript typé**.
2. Structure de run : **arène bornée + vagues chronométrées + boutique entre les vagues**. Caméra suit le joueur dans une arène plus grande que l'écran ; spawn hors écran mais dans l'arène.
3. Visée : **100 % automatique** (pas d'action `aim` dans l'InputMap ; chaque comportement d'arme choisit sa cible : plus proche, aléatoire, direction de déplacement…).
4. Emplacement : **`C:\Users\rapha\Projects\survivor-game\`** (nom de travail, renommable).
5. Thème de travail : **cyber-samouraï / ninja néon**. Lames et armes de ninja/samouraï futuristes, mais aussi armes à feu high-tech (pistolets laser, mitraillettes, bazookas) et armes imaginaires. Une couleur néon forte par arme (lisibilité). Direction artistique associée : silhouettes sombres + contours néon (option 2), à confirmer avant la fin de la Phase 3.

Décisions volontairement reportées : design final de la boutique (Phase 5), méta-progression (Phase 7), direction artistique (fin Phase 3). Level-up : **différé à la fin de la vague** (ADR 0006).

---

## Questions ouvertes
- Nom du jeu et univers / thème.
- Direction artistique (avant fin Phase 3).
- Variante de boutique finale (Phase 5).
- Forme de la méta-progression (Phase 7).
