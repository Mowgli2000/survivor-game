# Étape 7b — Niveaux de difficulté et mode infini (design + plan)

Date : 2026-10-03 · Statut : choix validés par le dev (D46 : difficulté par personnage, mode infini après victoire)

## Difficultés (Danger 0 à 5)
- **`DifficultyData`** (`data/difficulties/danger_0..5.tres`) : `level`, `name_key`, `description_key`, multiplicateurs de PV, de dégâts et d'apparitions des ennemis, bonus de taille des groupes, chance qu'un ennemi normal soit une élite, `double_final_boss`.
  | Danger | Effet (cumulatif) |
  |---|---|
  | 0 | Partie actuelle |
  | 1 | 1 % d'élites parmi les ennemis normaux |
  | 2 | + PV et dégâts ×1,15 |
  | 3 | + apparitions ×1,15, groupes +2 |
  | 4 | PV et dégâts ×1,3, 2 % d'élites |
  | 5 | + deux boss en vague 20 |
- **Par personnage** : gagner au Danger N débloque le N+1 pour ce perso (`Profile.best_difficulty_by_character`).
- **Application** : `Run` travaille sur une copie de `StageData` (`StageData.copy()`, événements copiés, ennemis partagés) ; `StageData.with_difficulty(d)` multiplie les courbes. Les données d'origine ne changent jamais.
- **Sélection** : 3e étape de l'écran de choix (perso → arme → Danger), seuls les niveaux débloqués sont actifs.

## Mode infini
- Après une **victoire** : bouton « Continuer en infini » sur l'écran de fin. La partie reprend (level-up, boutique, vague 21…).
- `StageData.endless` (sur la copie) : au-delà de la dernière vague, PV ×1,12, dégâts ×1,06 et apparitions ×1,04 **par vague** (composés), vagues de `duration_last`, le boss final revient toutes les 10 vagues. `WaveDirector` n'émet plus `run_won`.
- HUD : « Vague 23 (∞) ». Record par perso (`Profile.best_endless_wave_by_character`), enregistré à la mort sans recompter la partie (déjà comptée à la victoire).

## Tests
`StageData` (copie indépendante, multiplicateurs, double boss, extrapolation infinie, durée, boss toutes les 10 vagues), `WaveDirector` (pas de `run_won` en infini), `Profile` (niveaux débloqués par perso, aller-retour), `SaveService` (record infini), `Run` (difficulté appliquée, continuation en infini), écran de sélection (niveaux verrouillés), données (6 niveaux, Danger 0 neutre).
