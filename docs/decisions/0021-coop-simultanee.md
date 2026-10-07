# ADR 0021 — Coop : level-ups et boutique en même temps

**Date :** 2026-10-06 · **Statut :** appliqué (remplace le « à tour de rôle » de l'ADR 0017) · **corrigé par l'ADR 0022** (un seul focus GUI par fenêtre : focus des moitiés géré par `CoopScreens`)

## Contexte
En coop, les deux joueurs passaient entre les vagues l'un après l'autre (level-ups puis boutique de J1, puis de J2). Retour du dev : les deux joueurs doivent pouvoir acheter et choisir leurs cartes en même temps.

## Décision
- L'écran est coupé en deux moitiés (`CoopScreens`, 2 × `SubViewportContainer` de 960×1080). Chaque moitié contient les écrans du joueur : `LevelUpScreen` et `ShopScreen` en **mode compact** (`_init(p_compact)` : cartes plus étroites, polices réduites, pas de panneau de stats, Tab les affiche).
- Un `SubViewport` a **son propre focus GUI** : deux joueurs naviguent chacun avec sa manette. Les événements clavier et manette sont routés par `CoopScreens._input` vers le viewport du joueur qui possède le périphérique (`PlayerInput.owns_event`) ; la souris agit sur la moitié survolée. Remplace `CoopInputGate`.
- `Run` : `RunPlayer.level_up_screen`, `between_done` ; `_begin_between_waves()` lance les level-ups de tous les joueurs ; chaque joueur enchaîne level-ups puis boutique à son rythme ; la vague suivante démarre quand tous ont validé « Vague suivante » (`_on_shop_done(rp)`). Solo : même code, un seul joueur.

## Conséquences
- Les tests de tour (`current_player`, `_turn`) sont remplacés par des tests de flux parallèle.
- Les raccourcis manette d'un joueur sans manette (J2 au clavier) n'existent pas : J2 a besoin d'une manette (déjà vrai en jeu).
- Mise en page compacte à vérifier sur d'autres résolutions que 1080p.
