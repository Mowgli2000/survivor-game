# ADR 0018 — Sceaux et lieux (bestiaire par niveau de difficulté)

**Statut :** accepté (2026-10-04) — choix du dev D55

## Contexte
Les 6 niveaux de difficulté (« Danger 0-5 », ADR 0015) ne changeaient que des multiplicateurs. Le dev veut qu'en montant de niveau la carte, les monstres, les élites et les boss changent aussi, sans reprendre le système de rangs E à S de Solo Leveling.

## Décisions
1. **Sceaux** : les niveaux de difficulté deviennent les sceaux Cuivre, Fer, Argent, Or, Obsidienne, Astral. Les ids (`danger_0` … `danger_5`) ne changent pas (sauvegardes, déblocages par perso, défis).
2. **`BiomeData`** (`src/waves/biome_data.gd`, `data/biomes/`) : où mène le portail d'un sceau. Il contient le **bestiaire** (`enemy_swaps` : id d'un monstre de la phase de référence → monstre de ce lieu dans le même rôle) et l'**apparence de l'arène** (atlas de décor, teinte du sol, couleurs des murs, couleur des portails).
3. `DifficultyData.biome` relie un sceau à son lieu. `StageData.with_difficulty()` applique `apply_biome()` à la copie de la phase : les entrées d'apparition et les événements (boss) sont remplacés rôle par rôle. Les courbes, la durée des vagues et la structure ne changent pas : un seul fichier de phase à équilibrer.
4. Les monstres d'un lieu sont des `EnemyData` à part (ids `iron_*`…), qui reprennent les comportements existants (rôles : base, rapide, tireur, tank, chargeur, kamikaze, invocateur, mini-boss, boss final).
5. **Décor par lieu** : `tools/art/bake_map.gd` cuit un atlas par dossier `assets_src/drawn/map/decor_<lieu>/` → `assets/map/decor_atlas_<lieu>.tres`. `Arena.setup(rect, biome)`.
6. **Portails visibles** (`ArenaGates`) : un portail animé au milieu de chaque côté de l'arène, aux couleurs du lieu ; décoratifs (les règles d'apparition ne changent pas).
7. Un sceau sans lieu dédié utilise le donjon de pierre. Depuis la session 8, les six sceaux ont chacun leur lieu : Cuivre = donjon de pierre, Fer = temple englouti, Argent = forêt gelée, Or = citadelle infernale, Obsidienne = ruche souterraine, Astral = antre du dragon (test : un lieu par sceau).
8. **Pages d'atlas par lieu** (complément d'ADR 0009, session 8) : l'atlas unique dépassait 8192 px. `tools/sprites/bake_sprites.gd` range les bandes côte à côte et place les sprites ayant `"page": "<lieu>"` dans `assets/sprites/atlas_<lieu>.png`. Les monstres d'un lieu partagent une page, donc aucun changement de texture entre eux ; le stress test est inchangé (mesure alternée).
9. **Motifs de boss par lieu** : `ConeBreathPattern` (souffle en cône qui balaie), `ImpactZonesPattern` (zones annoncées au sol puis impact : stalactites, météores, acide), `WallPattern` (mur de projectiles avec une brèche), `SummonPattern.around_target` (invocation autour du joueur). Les invocations d'un boss viennent de son lieu (test).

## Conséquences
- Ajouter un lieu = un `BiomeData` + ses `EnemyData` + leurs sprites + un dossier de décor ; aucun code.
- Les défis « tuer un boss » visent un id précis : le boss du lieu correspondant.
- Les sprites de chaque lieu agrandissent l'atlas commun (à surveiller : taille de texture et stress test).
