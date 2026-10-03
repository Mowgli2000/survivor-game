# Thème des interfaces (chantier visuel 3/3)

**Date :** 2026-10-03 · **Statut :** validé (choix « reco » du dev)
**Décisions liées :** D33 (passe visuelle), D34 (coloré, pas sombre), ADR 0009/0010

## 1. Objectif

Un beau visuel cohérent sur **tous les écrans existants** : HUD, level-up, boutique, fin de vague, game over / victoire, panneau de stats. Les futurs menus (principal, pause, paramètres) l'utiliseront dès leur création.

Choix du dev (« reco ») :
1. Style **chibi néon** : gros contour noir (comme les sprites et les icônes), fond sombre légèrement violet, lueur néon colorée, coins bien arrondis.
2. Polices **Fredoka** (titres, chiffres, boutons) + **Nunito** (texte), licence OFL.
3. **Animations discrètes** : apparition (fondu + léger grossissement), cartes qui se soulèvent au survol/focus, rebond à l'achat, compteur de matériaux qui défile.
4. **Tous les écrans existants.**

Critères de réussite : un seul endroit définit l'apparence (couleurs, polices, styles) ; plus aucun style construit à la main dans les écrans (sauf couleurs sémantiques : rang, arme, mieux/pire) ; captures des écrans validées par le dev ; navigation clavier/manette inchangée (focus toujours visible).

Hors périmètre : nouveaux écrans/menus, refonte de la disposition des écrans, icônes de statistiques, sons d'interface (déjà faits).

## 2. Direction artistique de l'interface

- **Règle** : l'interface est « dessinée » comme les personnages : contour noir épais, aplats, un accent néon. Elle doit se lire d'un coup d'œil au-dessus d'une horde colorée.
- **Panneaux** : fond `#1b1730` (violet nuit, ~95 % opaque), contour noir 4 px, coins 16 px, lueur néon (ombre colorée floue de 10 px) de la couleur d'accent du panneau ; marges intérieures 20 px.
- **Boutons** : même grammaire, coins 14 px. États : normal (accent discret), survol/focus (accent plein + lueur plus forte), appuyé (fond plus sombre, décalé de 2 px vers le bas), désactivé (atténué, sans lueur). Le **focus** est toujours une bordure néon nette (lisible à la manette).
- **Texte** : blanc cassé `#eef0ff` avec **contour noir** (4 px texte, 8-10 px titres) : lisible sur n'importe quel fond, style autocollant chibi.
- **Hiérarchie** : titres Fredoka Bold 64-80 ; sous-titres Fredoka SemiBold 32 ; boutons Fredoka SemiBold 24-36 ; texte Nunito Bold 20-24 ; petites étiquettes Nunito ExtraBold 16-18 en majuscules.
- **Couleurs d'accent** (sémantiques, inchangées) : cyan `#66f2ff` (interface générale, level-up, titres), vert `#73ff8c` (matériaux, « mieux »), rouge `#ff6673` (PV, « pire », trop cher, défaite), or `#ffd94d` (victoire, élites), rangs I-IV (gris, bleu, violet, rouge), couleur propre de chaque arme.
- **Barres** (PV, XP) : contour noir 3 px, coins arrondis, fond sombre, remplissage coloré avec un reflet clair en haut.
- **Voiles d'écran** : assombrissement violet nuit (pas noir pur) pour rester dans la palette.
- **Animations** (toutes ≤ 0,25 s, sans bloquer l'entrée) : apparition des écrans (fondu 0→1 + échelle 0,94→1) ; cartes level-up/boutique qui apparaissent l'une après l'autre (décalage 0,04 s) ; carte/bouton survolé ou focus : échelle 1,04 ; achat : rebond de la carte ; compteur de matériaux qui défile vers la nouvelle valeur.

## 3. Architecture

- `assets/fonts/` : `Fredoka.ttf`, `Nunito.ttf` (variables) + licences OFL ; crédits dans `assets/CREDITS.md`.
- `src/ui/theme/ui_theme.gd` (`class_name UiTheme`) : construit **une fois** le `Theme` Godot (cache statique) : polices (`FontVariation` avec graisse), styles de `Button`, `PanelContainer`, `Panel`, `Label`, `ProgressBar`, `TooltipPanel`, et des **variations de type** nommées (`TitleLabel`, `SubtitleLabel`, `SmallLabel`, `CardButton`, `BigButton`…). Expose les couleurs de la palette (`UiTheme.ACCENT`, `GOOD`, `BAD`, `GOLD`, `TEXT`, `PANEL_BG`, `DIM`) et des fabriques de styles accentués (`panel_style(accent, strength)`, `card_style(accent, strength)`) pour les cartes dont la couleur dépend du rang.
- `src/ui/theme/ui_fx.gd` (`class_name UiFx`) : animations réutilisables, sans état : `pop_in(control, delay)`, `hover_lift(control)` (branche survol + focus), `bounce(control)`, `count_to(label, from, to, format)`.
- Chaque écran (`CanvasLayer`) pose `theme = UiTheme.get_theme()` sur son `Control` racine ; ses widgets utilisent les variations de type au lieu de `add_theme_*_override` (sauf couleurs sémantiques).
- Police par défaut du projet (`gui/theme/custom_font`) : Nunito, pour tout `Control` hors écran (debug).
- `DamageNumbers` : passe sur Fredoka Bold (cohérence des chiffres).

## 4. Tests et validation

- GUT : `UiTheme` (polices chargées, styles de bouton présents pour tous les états, variations de type définies, cache : même instance) ; chaque écran a le thème sur sa racine ; `UiFx.pop_in` amène l'opacité et l'échelle à 1 ; `count_to` finit sur la valeur exacte ; suites existantes (focus de la boutique, etc.) vertes.
- Captures : partie (HUD), level-up, boutique, fin de vague, game over, victoire. Montrées au dev.

## 5. Documentation

ADR 0011 (thème unique construit en code, variations de type, `UiFx`) ; `CLAUDE.md` (règle UI : thème + variations, pas de style à la main) ; `PROJECT_STATUS.md` ; crédits polices.
