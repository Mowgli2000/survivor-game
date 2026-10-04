# Brief artistique — personnages en anime cel-shading (génération IA)

> Choix du dev (2026-10-04) : rendu **anime cel-shading** ; images générées par le dev avec une IA image, découpe et intégration par Claude. Le showcase vectoriel (`art_showcase/`) reste une exploration : il ne sert plus de cible visuelle.

## 1. Ce que le jeu demande vraiment (et ce qu'il ne demande pas)

- **Taille en jeu** : le joueur fait ≈ 102 px de haut en 1080p, les ennemis 50-80 px. Les détails fins (mèches, plis, motifs) disparaissent. Il faut une **silhouette forte**, de **gros aplats**, un **trait épais** et **une couleur d'accent**.
- **Pas d'animation des membres nécessaire** : comme dans Brotato, les armes flottent autour du perso (ADR 0010). Une seule image par perso suffit : le jeu ajoute le rebond de marche, le retournement gauche/droite, le flash de coup et l'écrasement. C'est ce qui rend l'IA viable : générer 8 images cohérentes d'un même perso qui court est très difficile, en générer **une** belle est facile.
- **Vue** : 3/4 du dessus (caméra légèrement plongeante), perso de face ou de 3/4 face, en pied, pieds en bas de l'image.
- **Deux versions par perso** : l'**illustration** (proportions anime normales, pour l'écran de sélection et la page Steam) et le **sprite de jeu** (même perso, plus trapu : 4 à 5 têtes, tête un peu plus grosse, détails simplifiés).

## 2. Quatre concepts tirés des références (à choisir, ou à mélanger)

| Concept | Idée | Références qui l'inspirent | Accent |
|---|---|---|---|
| **A — Kunoichi de l'ombre** | Femme à la peau foncée, queue de cheval haute, combinaison noire, masque, brassards | Yoruichi, ninja violette, Soi Fon | violet néon |
| **B — Rōnin de la foudre** | Cheveux blancs en pointes, masque bas, kimono sombre et hakama, gantelet électrique | Rai, ninja aux éclairs, perso à masque noir | cyan électrique |
| **C — Sabreur spectral** | Corps bandé, cheveux blancs, katana à flamme verte, aura fantôme | Les deux planches « Aigoar » (bandages, démon) | vert jade |
| **D — Lame écarlate** | Queue de cheval rouge, écharpe rouge, pantalon bouffant, katana dans le dos, énergique | Kunoichi rousse, chibi au bandeau rouge | rouge + or |

Un concept peut devenir le perso principal, et les autres des persos à débloquer : ils partagent alors le même style.

## 3. Le bloc de style (à coller dans **chaque** prompt, sans le modifier)

Toujours le même texte : c'est lui qui garantit que tous les persos et ennemis ont l'air de venir du même jeu.

```text
anime cel-shading, clean bold black lineart, flat two-tone shading, limited palette, mostly dark clothing with one strong neon accent color, game character art, full body, centered, plain white background, no text, no watermark
```

Si l'outil le permet, garde aussi **la même référence de style** (image de style) et **le même seed** pour tout le casting.

## 4. Prompts

### Étape 1 — Concept (illustration)
4 images par concept, pose neutre debout. Remplacer `[CONCEPT]` :

```text
[CONCEPT], full body character design, standing neutral pose, front three-quarter view, [STYLE BLOCK]
```

- A : `young woman ninja with dark skin, high ponytail with purple ribbon, black sleeveless bodysuit, lower face mask, black arm guards, thigh-high boots, violet neon energy wisps`
- B : `young male ronin, spiky white hair, black lower face mask, dark kimono with sleeveless top, wide black hakama pants, glowing cyan lightning gauntlet on one arm, katana at the hip`
- C : `lean swordsman wrapped in white bandages, messy white hair, glowing green eyes, torn bandage cloth flowing, katana with green spectral flame blade`
- D : `energetic young woman samurai, spiky red high ponytail, long red scarf, black crop top, baggy dark pants, bandaged hands, katana on her back, sandals`

### Étape 2 — Planche de référence (une fois le concept choisi)
Avec l'image retenue comme **référence de personnage** :

```text
character turnaround sheet of the same character, front view, three-quarter front view, side view, back view, same outfit and colors in every view, [STYLE BLOCK]
```

### Étape 3 — Sprite de jeu
Avec la même référence :

```text
same character as a game sprite, chibi-leaning proportions 4 heads tall, slightly bigger head, simplified details, thick outline, viewed from slightly above (top-down three-quarter camera), front three-quarter view, standing ready pose, feet at the bottom, [STYLE BLOCK]
```

Garde l'image si, réduite à 100 px de haut, tu reconnais encore le perso (le test d'échelle du showcase sert à ça).

### Ennemis (même méthode)
```text
[ENEMY], small monster enemy for a top-down action game, simple bold shapes, readable silhouette, viewed from slightly above, [STYLE BLOCK]
```
Par exemple : `red horned imp demon`, `armored oni brute`, `masked shadow ninja minion`, `floating paper lantern ghost`. Les ennemis de base restent plus simples que le joueur, pour que le joueur ressorte.

## 5. Ce que tu me déposes

Dossier : `art_source/incoming/` (créé, ignoré par Godot).

- **PNG, la plus grande taille possible** (1024 px de haut ou plus).
- Fond blanc uni ou transparent (je détoure).
- Un fichier par image, nommé simplement : `concept_A_1.png`, `turnaround_A.png`, `sprite_A.png`, `enemy_imp.png`…

## 6. Ce que je fais ensuite

1. Détourage, recadrage (pieds en bas, perso centré), nettoyage du contour, harmonisation des couleurs entre persos.
2. Réduction à la taille du jeu, avec un contour un peu renforcé pour rester lisible à 100 px.
3. Intégration dans l'atlas existant (ADR 0009) : rebond de marche, retournement, flash de coup, ombre au sol. Aucune animation dessinée n'est nécessaire.
4. Capture en jeu avec 650 ennemis pour juger la lisibilité réelle, puis ajustements.

## 6b. Commande de préparation (une image → sprite animé)

```text
Godot.exe --headless --path . -s res://tools/art/prepare_ai_sprite.gd -- --in=<chemin de l'image> --id=<id_du_sprite> [--flip] [--bg=0.72]
```

- `--flip` si le perso regarde vers la gauche (le jeu attend un perso tourné vers la droite).
- `--bg` : seuil de clarté du fond à retirer (baisser si des zones claires du fond restent).
- Produit `assets_src/ai/<id>/idle_0..5.png` et `walk_0..7.png` (respiration, petits sauts avec écrasement), puis ajouter l'id dans `tools/sprites/sprites.json` et lancer `tools/bake_sprites.ps1`.
- Vérifier en jeu : `Godot.exe --path . res://src/debug/capture.tscn -- --time=40 --character=<id du perso> --out=<png>`.

Premier test (2026-10-04) : image Freepik avec filigrane (perso de test `ai_test`, **provisoire, à ne pas publier**, fichiers exclus de Git). La chaîne fonctionne ; à régler : le perso paraît plus petit que les ennemis.

## 7. Limites à connaître

- **Cohérence** : l'IA dérive d'une image à l'autre (tenue, couleurs). D'où le bloc de style fixe, la référence de personnage et le tri : on génère beaucoup, on garde peu.
- **Droits** : vérifier que l'outil autorise l'usage commercial des images générées (conditions de l'abonnement). Ne pas copier un personnage existant (Yoruichi, etc.) : les références servent d'inspiration, les prompts n'en citent aucun.
- **Steam** : Steam demande de déclarer l'usage de contenu généré par IA dans le formulaire de la page du jeu.
- Les noms d'outils et leurs fonctions (référence de personnage, référence de style, seed) changent vite : utilise l'équivalent de ton outil.
