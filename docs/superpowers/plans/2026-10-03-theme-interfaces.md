# Thème des interfaces — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un thème « chibi néon » unique (Fredoka + Nunito, contours noirs, lueur néon) appliqué à tous les écrans, avec des animations discrètes.

**Architecture:** `UiTheme` construit et met en cache un `Theme` Godot (polices, styles, variations de type) et expose la palette + des fabriques de styles accentués ; `UiFx` fournit des animations sans état (désactivables : `UiFx.reduce_motion`). Chaque écran pose le thème sur sa racine et utilise les variations de type.

**Tech Stack:** Godot 4.7.2, GDScript typé, GUT 9.6.1, polices variables OFL.

**Spec:** `docs/superpowers/specs/2026-10-03-theme-interfaces-design.md`

## Global Constraints

- UI en lecture seule ; textes via clés de traduction ; navigation clavier/manette inchangée, focus toujours visible.
- Animations ≤ 0,25 s, jamais bloquantes, désactivables (`UiFx.reduce_motion`, règle `.claude/rules/ui-code.md`).
- Pas de style construit à la main dans les écrans, sauf couleurs sémantiques (rang, arme, mieux/pire, trop cher).
- Commentaires de code en anglais.

## Review Focus

- Écran ouvert puis rouvert très vite (level-up enchaînés) : animations relancées sans état incohérent (opacité/échelle à 1 à la fin) → test Task 1.
- `reduce_motion` activé : tout s'affiche immédiatement → test Task 1.
- Focus manette après reconstruction de la boutique : inchangé → tests existants Task 4.
- Pivot des animations sur des contrôles de taille 0 au moment de l'appel (avant mise en page) → test Task 1.
- Compteur de matériaux qui change plusieurs fois pendant son défilement : finit sur la dernière valeur → test Task 1.

---

### Task 1: UiTheme, UiFx, polices
**Files:** Create `src/ui/theme/ui_theme.gd`, `src/ui/theme/ui_fx.gd`, `assets/fonts/*` · Modify `project.godot` (police par défaut), `assets/CREDITS.md` · Test `tests/unit/test_ui_theme.gd`
- [ ] Tests : thème mis en cache (même instance) ; police par défaut = Nunito ; styles `Button` pour normal/hover/pressed/disabled/focus ; variations `TitleLabel`, `SubtitleLabel`, `SmallLabel`, `BigButton` ; `panel_style(accent)` a un contour noir et une ombre de la couleur d'accent ; `pop_in` → opacité 1 et échelle 1 après l'animation ; `reduce_motion` → immédiat ; `count_to` relancé en cours de route finit sur la dernière valeur.
- [ ] Implémentation (cf. spec §2-3) ; police par défaut du projet ; crédits.
- [ ] Tests verts ; commit `feat: UI theme (chibi neon) and UI animations`.

### Task 2: HUD, panneau de stats, IconTile, chiffres de dégâts
- [ ] Test : la racine du HUD porte le thème ; le panneau de stats utilise `UiTheme`.
- [ ] HUD : thème sur la racine, barres via `UiTheme.bar_styles(color)`, libellés en variations (vague/chrono Fredoka), compteur de matériaux qui défile. StatsPanel : style de panneau du thème, titre `SubtitleLabel`, couleurs `UiTheme.GOOD/BAD/TEXT`. IconTile : contour noir + lueur du rang. DamageNumbers : Fredoka Bold.
- [ ] Tests verts ; capture ; commit `feat: themed HUD, stats panel and icon tiles`.

### Task 3: Level-up, fin de vague, game over
- [ ] Test : racines thémées ; les cartes de level-up utilisent `UiTheme.card_style`.
- [ ] Voiles `UiTheme.DIM` ; titres `TitleLabel` ; cartes accentuées par rang avec `hover_lift` et apparition décalée ; game over/victoire : titre `TitleLabel` (or pour la victoire, rouge pour la défaite), bouton `BigButton`, apparition.
- [ ] Tests verts ; captures `--levelup`, `--die` ; commit `feat: themed level-up, wave end and game over screens`.

### Task 4: Boutique
- [ ] Test : racine thémée ; tests de focus existants verts.
- [ ] Cartes `card_style` par rang + `hover_lift` + apparition décalée + rebond à l'achat ; boutons thémés (`BigButton` pour « Vague suivante ») ; titre `TitleLabel` ; matériaux qui défilent ; armes possédées en style du rang.
- [ ] Tests verts ; capture `--shop` ; commit `feat: themed shop`.

### Task 5: Validation et documentation
- [ ] Captures de tous les écrans ; ADR 0011 ; `CLAUDE.md` (règle UI) ; `PROJECT_STATUS.md` (D40) ; revue finale.
