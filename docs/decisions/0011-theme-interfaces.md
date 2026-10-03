# ADR 0011 — Thème d'interface unique (« chibi néon »)

**Statut :** accepté (2026-10-03) — chantier visuel 3/3, spec `docs/superpowers/specs/2026-10-03-theme-interfaces-design.md`

## Contexte
Chaque écran construisait ses propres styles dans le code (couleurs, bordures, tailles), avec la police par défaut de Godot. Le dev veut un beau visuel cohérent sur toutes les interfaces, dans le style des personnages et des icônes.

## Décisions
1. **Un seul `Theme`, construit en code** par `UiTheme` (`src/ui/theme/ui_theme.gd`) et mis en cache. Il est plus facile à relire et à tester qu'un `.tres` édité à la main, et il ne contient que des valeurs. Il définit :
   - les polices : Fredoka pour les titres, chiffres et boutons ; Nunito pour le texte ; polices variables avec la graisse via `FontVariation` ;
   - les styles de `Button`, `PanelContainer`, `ProgressBar` et des info-bulles ;
   - des **variations de type** : `TitleLabel`, `SubtitleLabel`, `ValueLabel`, `SmallLabel`, `BigButton`.
2. **Grammaire visuelle** : contour noir de 4 px, fond violet nuit, lueur néon (ombre floue) de la couleur d'accent, coins arrondis. Le texte a un contour noir. Le focus clavier ou manette est un cadre néon net.
3. **Palette sémantique** exposée par `UiTheme` : `ACCENT`, `GOOD`, `BAD`, `GOLD`, `XP`, `TEXT`, `MUTED`, `DIM`. Les éléments colorés par le rang ou par l'arme utilisent `card_style(accent)`, `panel_style(accent)`, `focus_style()` et `bar_styles(color)`.
4. **Chaque écran** pose `theme = UiTheme.get_theme()` sur son `Control` racine. Les widgets utilisent les variations ; seules les couleurs sémantiques et les tailles liées à la mise en page restent réglées sur chaque widget.
5. **Animations** dans `UiFx` (`src/ui/theme/ui_fx.gd`), sans état et toutes de 0,35 s au plus :
   - apparition (fondu et grossissement), avec un décalage d'une carte à l'autre ;
   - soulèvement au survol ou au focus ;
   - rebond à l'achat ;
   - défilement des compteurs.
   `UiFx.reduce_motion` les coupe toutes : ce sera le futur réglage d'accessibilité.
6. Police par défaut du projet : Nunito. Les chiffres de dégâts utilisent Fredoka.

## Conséquences
- Un nouvel écran ou menu pose le thème sur sa racine et utilise les variations : pas de `StyleBoxFlat` construit à la main.
- Changer l'apparence générale se fait dans `UiTheme`, à un seul endroit.
- Un test vérifie que tous les écrans de la partie portent le thème.
