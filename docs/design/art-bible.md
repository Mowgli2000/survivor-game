# Art Bible: Survivor Game (titre de travail)

> **Status**: Approved
> **Owned By**: art-director
> **Last Updated**: 2026-10-04
> **Art Director Sign-Off (AD-ART-BIBLE)**: `SKIPPED 2026-10-04 — solo mode`

Source des décisions : `PROJECT_STATUS.md` D34, D36, D50, D51 · vision et piliers : `docs/design/gdd.md` · art par code : ADR 0016 · interface : ADR 0011.
Les marques sont des propositions que le dev doit valider.

## 1. Visual Identity Statement

**Règle d'or : « Lisible d'abord, puissant ensuite » — en jeu, chaque élément doit se lire en silhouette au milieu de 650 ennemis ; le spectacle manga (aura, yeux qui brillent) est réservé aux moments forts et aux illustrations.**

Triangle de références (remplace la section 9) :
- **Rendu = Brawlhalla** : trait noir épais constant, aplats + UNE ombre dure, proportions trapues (grosse tête, grosses mains, jambes courtes), silhouette franche. À éviter : copier ses personnages ou son cadrage de profil.
- **Lisibilité/gameplay = Brotato** : petites armes flottantes en positions fixes autour du perso, perso **mains vides** en jeu, ennemis lisibles par forme et taille. À éviter : son style patate/minimaliste.
- **Thème = Solo Leveling** : chasseurs contre monstres sortis de portails/donjons, rangs, éveil, ombres violettes. **Archétypes uniquement** : aucun design, nom, logo ou costume repris.
- **Influence manga (goût du dev : Naruto, Bleach, One Punch Man, « aura farming »)** : poses de puissance, auras, yeux lumineux, lignes de vitesse → **cartes de sélection, level-up, entrée d'élite/boss, VFX**. Jamais sur les sprites de foule.

Principes :
1. **La silhouette avant le détail** — Test : si un élément ne se lit pas en noir plein à 64 px de haut, on le supprime ou on le grossit. Pilier : *sensation de puissance* (le joueur voit ce qu'il détruit).
2. **Calme en jeu, explosion aux moments clés** — Test : en cas de doute entre ajouter un effet permanent ou un effet ponctuel, choisir le ponctuel (≤ 1 s) sur un événement (level-up, élite, boss, fusion). Piliers : *progression constante*, *sensation de puissance*.
3. **Une couleur = une information** — Test : si une couleur saturée n'a pas de sens gameplay (classe, danger, rang, famille, statut), la désaturer. Piliers : *décisions fréquentes* (boutique lisible en 2 s), *synergies* (familles reconnaissables).

## 2. Mood & Atmosphere

| État | Cible émotionnelle | Lumière / valeur | Descripteurs | Énergie |
|---|---|---|---|---|
| Vagues 1-7 | Chasseur qui prend ses marques | Sol mi-ton lavande, contraste moyen, VFX rares | net, aéré, froid, donjon calme | 3/10 |
| Vagues 8-15 | Montée de tension | Même sol ; densité et VFX joueur montent, ennemis élites dorés | dense, rythmé, crépitant | 6/10 |
| Vagues 16-20 + infini | Débordement maîtrisé (« je suis une armée ») | Sol inchangé (jamais assombri) ; le chaos vient des VFX additifs du joueur | saturé, électrique, écrasant, triomphant | 9/10 |
| Boutique | Respiration, calcul | Voile `UiTheme.DIM` violet nuit ; cartes colorées par rang | posé, chaleureux, marchand de portail, lisible | 2/10 |
| Level-up | Éveil (« Arise ») | Flash court + aura de la couleur de classe autour du joueur, yeux qui brillent | ascension, éclat, montée | pic 8/10 puis 2 |
| Entrée élite | Alerte | Liseré or + court éclat doré au spawn | menace, prestige | +2 |
| Entrée boss (moment « aura ») | Choc et défi | Portail qui se déchire, trauma caméra, aura sombre du boss (2 tons max), barre `BossBar` | écrasant, solennel, rouge-violet | 10/10 puis 7 |
| Victoire | Gloire | Or `UiTheme.GOLD` dominant, pose de puissance (carte) | lumineux, chaud, épique | 7/10 |
| Défaite | Chute, envie de revanche | Voile `DEFEAT_DIM` bordeaux, désaturation | lourd, bref, pas punitif | 2/10 |
| Menus / choix du perso | Fantasme du chasseur | Fond sombre violet ; illustration de carte en grand, rim light de la couleur de classe | héroïque, manga, invitant | 5/10 |

Règles :
- Le **sol ne change jamais de valeur** selon l'état (D34 : pas de jeu trop sombre). L'ambiance passe par VFX, voiles d'UI et caméra.
- Aucun effet plein écran > 0,3 s pendant le combat ; flash plein écran réservé au boss et respectant les réglages (`Settings`).

## 3. Shape Language

Grammaire de formes (lecture instantanée du rôle) :
- **Rond / massif** = encaisse (tank, spawner, boss lourd).
- **Pointu / triangle vers l'avant** = rapide ou fonce (runner, charger, kamikaze).
- **Vertical / fin + objet tenu** = attaque à distance (shooter).
- **Humanoïde trapu, épaules larges** = joueur et grunt (le joueur se distingue par couleur d'aura + taille 192 px vs 128 px).

Paliers de taille (rayon de collision `EnemyData.radius` → hauteur cuite proposée) :

| Palier | Rayon | Hauteur cuite | Qui |
|---|---|---|---|
| S | 14-16 | 112-128 px | runner, kamikaze, shooter |
| M | 18-20 | 128 px | grunt, charger |
| L | 26-30 | 160-176 px | spawner, tank |
| Boss | 40-48+ | 256-320 px | mini-boss, boss final |
| Joueur | 16 | 192 px | tous les persos jouables |

Règles :
- Une **caractéristique distinctive par archétype**, visible en silhouette (défenses de l'orc, museau du loup, bâton du gobelin, abdomen lumineux de l'insecte…).
- Les monstres d'un même palier ont des **silhouettes de contour différentes** (pas deux humanoïdes S).
- Joueur : silhouette verticale, posture droite, tête lisible (yeux visibles) ; monstres : penchés vers l'avant, tête basse.
- Environnement : géométrie **orthogonale et lourde** (dalles carrées, blocs, arches) pour contraster avec les créatures organiques ; portails = cercles/ellipses (seule forme ronde du décor = lieu d'apparition).
- Armes flottantes : formes simples et iconiques (une lame, un arc, un orbe, une fiole), lisibles à ~40 px.

## 4. Color System

Palette principale :

| Couleur | Hex | Sens |
|---|---|---|
| Encre | `#000000` (trait) · `#1b1026` (ombres décor) | Contour constant de tout ce qui vit ; liant du style |
| Pierre lavande | `#45436e` (sol de base) | Le donjon : mi-ton neutre froid sur lequel tout ressort |
| Violet d'ombre | `#a259ff` | Pouvoir des portails, magie d'ombre, l'assassin |
| Bleu mana | `#59b8ff` (= `UiTheme.XP`) | Expérience, mana, système de « l'éveil » |
| Or | `#ffd94d` (= `UiTheme.GOLD`) | Élite, victoire, récompense |
| Rouge danger | `#ff6673` (= `UiTheme.BAD`) | PV, dégâts subis, menace |
| Vert matériaux | `#73ff8c` (= `UiTheme.GOOD`) | Matériaux, valeurs « meilleures » |

Couleurs sémantiques existantes (à conserver, ne pas modifier sans ADR) :
- Rangs `src/core/tiers.gd` : I gris `#c7ccdb` · II bleu `#59a6ff` · III violet `#bf66ff` · IV rouge `#ff4d59`.
- UI `src/ui/theme/ui_theme.gd` : `TEXT #eef0ff`, `ACCENT #66f2ff`, `GOOD`, `BAD`, `GOLD`, `XP`, `PANEL_BG`, `DIM`.
- Élite = contour or (système `elite` de `tools/sprites/sprites.json`). Coup reçu = flash blanc. Ces deux signaux sont **réservés** : aucun monstre n'a d'or ni de blanc pur dominant.
- Familles (`data/families/*.tres`, `color`) : à recolorer avec le thème : `blade` acier `#d8e0ff` · `gun` (arcs) vert forêt `#66e066` · `energy` (magie) cyan arcane `#66f2ff` · `explosive` (alchimie) orange `#ff8a2b`.

Couleur d'aura par classe (une seule par classe : yeux, liseré, rim light de carte, aura de level-up, VFX signature) :

| Classe | Aura | Hex | Note |
|---|---|---|---|
| Assassin (`hero`) | Violet d'ombre | `#a259ff` | Validé (pilote D51) |
| Chasseur de rang E (`drifter`) | Bleu mana | `#4dc8ff` | Novice = couleur « système » |
| Épéiste (`ronin`) | Orange braise | `#ff7a2b` | |
| Archer (`gunslinger`) | Vert émeraude | `#3ddc84` | Proche du vert matériaux : garder en liseré, pas en aplat |
| Contrebandier (`merchant`) | Ambre | `#ffb030` | Plus orangé que l'or élite |
| Mage (prévu) | Magenta arcane | `#ff4fd8` | |
| Berserker (prévu) | Rouge sang | `#e0283a` | Exception au rouge danger : aura seulement aux moments forts |
| Alchimiste / Paladin (plus tard) | Vert acide `#b6ff3a` / Blanc doré `#fff1b0` | | |

Accents des monstres : voir table section 5. Règle : **chaque perso/monstre a au moins un accent clair ou saturé** (yeux, bouche, bijou, fissure) sinon il disparaît dans la foule (leçon du loup gris foncé).

Valeurs :
- Sol : luminance (HSV V) **35-50 %**, saturation ≤ 35 %, contraste des joints ≤ 15 %. Jamais de noir ni de blanc dans le sol.
- Personnages/monstres : au moins une masse de valeur **≥ 20 points** d'écart avec le sol (plus claire ou plus foncée) + le trait noir.
- Projectiles ennemis : rouge-rose `#ff3d6e` à cœur clair + contour noir ; jamais une couleur de famille du joueur.

Daltonisme (secours obligatoires) :
- Rangs : chiffre romain I-IV + épaisseur du cadre, pas seulement la couleur.
- Élite : contour or **plus épais** + taille ×1,15 (forme, pas seulement teinte).
- Danger/projectiles ennemis : forme dédiée (losange ou pointe) + son ; ne pas opposer rouge/vert comme seul signal.
- Statuts : feu = flammèches montantes, glace = cristaux anguleux, foudre = zigzag (forme distincte par statut).

## 5. Character Design Direction

Deux images par perso jouable (D51) ; une seule pour les monstres.

| Niveau | Carte (sélection) | Sprite en jeu |
|---|---|---|
| Détail | Haut : plis, coutures, mèches au trait ; 2-3 tons d'ombre dure ; reflets nets | Bas : aplats + 1 ombre dure, 3-5 masses de couleur max |
| Pose | Dynamique, arme signature en main, aura manga | Debout, **mains vides**, trois-quarts vers la droite, vue ~35° du dessus |
| Effets | Aura/fumée en formes plates détourées, rim light colorée | Aucun effet dessiné (le moteur ajoute ombre au sol, respiration, poussière) |
| Taille | 1024×1536 | Source 1024×1024 ou 1024×1536 → 192 px cuits |

Persos jouables (ids inchangés, seuls visuels et noms changent) :

| id | Classe | Trait de silhouette | Aura | Arme de carte | Look en jeu |
|---|---|---|---|---|---|
| `hero` | Assassin à dagues | Long manteau à capuche | Violet `#a259ff` | Deux dagues | Manteau noir, liserés violets, ceinture brune boucle argent, yeux violets (`art_source/ai/assassin.png`) ✔ |
| `drifter` | Chasseur de rang E | Veste courte, sac à dos, allure de débutant | Bleu `#4dc8ff` | Épée courte simple | Veste bleu délavé, pantalon clair, badge de rang « E » |
| `ronin` | Épéiste / Chevalier | Épaulière massive asymétrique | Orange `#ff7a2b` | Épée longue | Cuirasse acier clair, cape orange, cheveux en pointes |
| `gunslinger` | Archer | Capuche courte + carquois dans le dos | Vert `#3ddc84` | Arc long | Tunique brun-vert, cape courte, brassard clair |
| `merchant` | Contrebandier de portail | Gros sac / pochettes, chapeau large | Ambre `#ffb030` | Bourse + couteau | Gilet brun, pièces et fioles accrochées, écharpe ambre |
| (prévu) | Mage | Chapeau ou col haut + bâton (carte) | Magenta `#ff4fd8` | Bâton à orbe | Robe sombre, motifs magenta |
| (prévu) | Berserker | Très large, torse nu, cicatrices | Rouge `#e0283a` | Hache double | Peau hâlée, fourrure claire sur épaules |

Bestiaire (rôles inchangés ; tailles d'après `data/enemies/*.tres`) :

| id | Créature | Rôle | Trait de silhouette | Palette / accent | Taille |
|---|---|---|---|---|---|
| `grunt` | Orc | Base | Défenses, épaulière | Peau vert mousse, cuir brun, pagne rouge, fer rouillé ✔ | M (18) |
| `runner` | Loup | Rapide | Museau long, corps en flèche | Fourrure gris cendre clair, dos plus foncé, yeux jaunes, gueule rouge ✔ | S (14) |
| `tank` | Golem de pierre | Encaisse | Bloc carré, bras énormes | Grès ocre (pas gris : se confondrait avec le sol), fissures orange lumineuses | L (30) |
| `charger` | Sanglier cuirassé | Fonce | Coin horizontal, défenses blanches | Brun roux, défenses ivoire, yeux rouges | M (20) |
| `shooter` | Gobelin chaman | Distance | Petit, bâton à crâne vertical | Peau ocre jaune, capuche turquoise, orbe rose-rouge (= couleur des tirs ennemis) | S (16) |
| `kamikaze` | Insecte explosif (scarabée) | Explose | Abdomen gonflé, pattes fines | Carapace sombre, abdomen orange lumineux pulsant | S (14) |
| `spawner` | Nid d'araignée | Invoque | Masse ronde de toile + pattes | Cocon crème, nombreux yeux rouges, araignées sortantes | L (26) |

L'orc (`grunt`) est l'humanoïde le plus nombreux : **aucune classe jouable en vert mousse**.

Boss et lieux : **un lieu par sceau** (ADR 0018, décision du dev 2026-10-04). Pas de rangs E à S ni d'ordre des arcs de Solo Leveling (trop proche de la série) : archétypes fantasy génériques.

| Sceau | Lieu | Mini-boss (vague 10) | Boss final (vague 20) |
|---|---|---|---|
| Cuivre | Donjon de pierre | Serpent venimeux (`ronin`) | Chevalier démon (`shogun`) |
| Fer | Temple englouti | Gardien de pierre (`iron_boss_mini`) | Idole colossale (`iron_boss_final`) |
| Argent | Forêt gelée | Ours de givre | Géant des glaces |
| Or | Citadelle infernale | Molosse à trois têtes | Seigneur démon |
| Obsidienne | Ruche souterraine | Mante géante | Reine de la ruche |
| Astral | Antre du dragon | Wyverne | Dragon ancien |

Temple englouti (Fer) : sol grès (teinte chaude), murs ocre, portails cyan ; monstres : soldat squelette, chauve-souris, gargouille, gardien de bronze, chevalier squelette, crâne maudit, sarcophage.

Élites : même sprite, contour or (`"elite": true` dans `sprites.json`) + taille ×1,15 ; aucun redessin.

Expression :
- Yeux manga grands et lisibles sur joueur et boss ; yeux **lumineux** (couleur d'aura, petite tache claire) = signal de puissance, réservé au joueur, aux élites et aux boss.
- Monstres de base : yeux petits, jaunes ou rouges, sans lueur animée.
- Cartes : regard déterminé, sourire en coin ou mâchoire serrée ; pas de visage neutre.
- Mouvement du joueur procédural (`src/player/player_motion.gd`) ; pantin 2D reporté après validation de tous les persos jouables (D51).

## 6. Environment Design Language

Architecture :
- Donjon de portail : salle carrée bornée (~2400 px, zoom caméra 1,3), dalles de pierre, piliers et murs en bordure uniquement, arches effondrées.
- Culture : « donjon instancié » apparu par un portail — pierre ancienne + cristaux de mana, traces des chasseurs précédents (armes cassées, os, sacs abandonnés).

Sol (`tools/art/make_map.py` → `assets/map/`) :
- Base pierre lavande `#45436e`, dalles carrées, joints à faible opacité (≤ 0,18), quelques fissures et taches.
- Pas de motif répétitif visible à l'échelle de l'écran : 3-4 variantes de dalles mélangées.
- Aucun symbole néon (à supprimer de l'ancien thème) ; pas de grandes runes lumineuses au centre (bruit visuel sous les ennemis).

Décor (props) :

| Prop | Rôle | Densité |
|---|---|---|
| Torches murales | Points chauds orange en bordure | 1 tous les ~400 px de mur |
| Cristaux de mana (bleu/violet) | Accent froid, rappel des portails | 4-8 groupes, bords et coins |
| Os, crânes, armes cassées | Histoire des chasseurs morts | Petits, au sol, 10-20, faible contraste |
| Piliers / blocs effondrés | Cadre, profondeur | Bordure uniquement |
| Portails (cercles d'invocation) | Lieu et récit des apparitions | Animés : s'ouvrent aux points d'apparition (montrent d'où vient le danger) |

Règles :
- Zone centrale ≈ 70 % de l'arène : sol nu + petits détails plats ; aucun prop haut (ne doit jamais masquer un ennemi ou un projectile).
- Décor : contraste max ~60 % de celui des personnages, contour plus fin ou encre `#1b1026` au lieu du noir pur.
- Le décor n'utilise pas : or (élite), rouge danger, rose-rouge des tirs ennemis.
- Récit d'apparition : les ennemis sortent d'un portail violet (petit VFX de déchirure) ; le boss sort d'un grand portail (moment « aura », section 2).

VFX (`src/vfx/vfx.gd`, additif, un seul nœud) — restylage de l'ancien néon :
- Écoles : ombre (violet), feu (`BURN` : orange-jaune, flammèches), glace (`SLOW` : cyan pâle, éclats anguleux), foudre (`SHOCK` : jaune-blanc, zigzags), sacré (blanc doré, Paladin plus tard).
- Formes plates à bord net, 2 tons max ; pas de dégradé doux ni de fumée réaliste.
- L'additif ne doit jamais blanchir l'écran : limiter l'opacité cumulée quand 650 ennemis brûlent.

## 7. UI/HUD Visual Direction

Hors portée de cette passe — interface : voir ADR 0011 (`docs/decisions/`)

## 8. Asset Standards

Formats et tailles :

| Type | Source | Final en jeu | Fichier source |
|---|---|---|---|
| Carte de perso | PNG 1024×1536, fond transparent | Écran de sélection (non cuite) | `art_source/ai/<id>_card.png` |
| Sprite joueur | PNG 1024×1024 ou 1024×1536, transparent | 192 px de haut (`height` dans `sprites.json`) | `art_source/ai/<id>.png` |
| Sprite monstre | PNG 1024×1024, transparent | 128 px (défaut) ; paliers section 3 | `art_source/ai/<id>.png` |
| Boss | PNG 1024×1536 | 256-320 px | `art_source/ai/<id>.png` |
| Icônes armes/objets | SVG ou PNG 256×256 | Icône UI + arme flottante | `assets/icons/weapons/`, `tools/icons/make_icons.py` |
| Sol et décor | SVG (par code) | `assets/map/decor_atlas.tres` | `tools/art/make_map.py` → `assets_src/drawn/` |

Nommage :
- Sources IA : `art_source/ai/<id>.png` et `<id>_card.png`, `<id>` = id de contenu (`grunt`, `runner`, `hero`…) ; variantes de travail `<id>_v1.png`, `<id>_v2.png` dans `art_tests/` (non versionné).
- Assets générés : `assets_src/ai/ai_<id>` (sortie de `prepare_ai_sprite.gd`).
- Nouveaux assets hors pipeline : `[catégorie]_[nom]_[variante]_[taille].[ext]` (ex. `vfx_portal_open_large.png`).
- **Ne jamais renommer un id de contenu** (sauvegardes) : on change le visuel et la clé de nom affichée, pas l'id.

Pipeline :
1. `python tools/art/gen_image.py` (modèle **`gpt-image-2.5-sunburst`** par défaut depuis le 2026-10-04, `--model` pour en changer ; `--style`, `--image` pour la cohérence d'un perso, fond transparent). Puis **toujours** `tools/art/fill_alpha_holes.gd` sur l'image retenue (ombres et auras semi-transparentes à l'intérieur du perso).
2. `tools/art/prepare_ai_sprite.gd` : 1 image → idle 6 + walk 8 images (respiration/sautillement procéduraux + ombre au sol).
3. Entrée dans `tools/sprites/sprites.json` : `src`, `height`, `"glow": "#000000"` (pas de halo néon pour les sprites IA), `"elite": true` pour les monstres.
4. `powershell -ExecutionPolicy Bypass -File tools/bake_sprites.ps1` → atlas unique `assets/sprites/atlas.png`.
5. Contrainte perf : un seul atlas partagé ; vérifier sa taille et le stress test (≥ 100 FPS moyen, D37) après ajout de monstres.

Structure de prompt (préfixe canonique = fichier de style, ne pas le réécrire dans le prompt) :
- Sprites : `--style tools/art/style_block.txt`, qui commence par « 2D game sprite for a top-down roguelite, in the style of Brawlhalla character art: thick clean black outline of constant weight, flat colors with one hard cel-shadow tone… Transparent background, no ground, no shadow on the floor, no text, no frame. »
- Cartes : `--style tools/art/style_portrait.txt`, qui commence par « Character select illustration for a dark-fantasy roguelite, clean anime / manga key art style, like a Brawlhalla splash art… Anatomically correct hands: every weapon is firmly gripped… Transparent background, no ground, no text, no frame. »
- Ligne sujet (modèle) :
  `Subject: <creature/class>, <silhouette trait>. Palette: <main colors>, accent <light or saturated accent>. <Pose: standing, empty hands | dynamic pose holding <weapon> in <hand>>. Eyes: <color>, <glowing for card/boss>. Whole body with wide margin, character about 75% of image height.`
- Cohérence carte ↔ sprite : générer la carte avec `--image art_source/ai/<id>.png` (ou l'inverse), jamais de description libre seule.

Checklist de génération :
- [ ] 2 variantes par requête, choisir la meilleure.
- [ ] Mains et armes : orientation de la lame, prise, nombre de doigts. Sinon régénérer ou corriger par retouche de référence.
- [ ] Sprite en jeu : mains **vides**.
- [ ] Cadrage : corps entier, pieds visibles, marge large (perso ≈ 75 % de la hauteur).
- [ ] Transparence réelle (pas de fond gris/damier peint).
- [ ] Au moins un accent clair ou saturé ; pas d'or ni de blanc pur dominant sur un monstre.
- [ ] Silhouette en noir plein reconnaissable à 64 px.
- [ ] Test en jeu avec foule : `& "C:\Program Files\Godot\Godot.exe" --path . res://src/debug/capture.tscn -- --time=20 --stress --out=<png>` ; le nouvel élément se repère en < 1 s.
- [ ] Aperçu rapide de la planche : `tools/art/preview_sheet.gd -- --out=<png> --id=<id>`.

Outils : icônes `tools/art/make_icon.gd --in --out` (128 px, armes horizontales pointe à droite) ; décor `make_icon.gd --height=N` vers `assets_src/drawn/map/decor/`, puis `tools/bake_sprites.ps1`.

Leçons IA (règles) :
- Références : la carte de l'assassin (`art_source/ai/assassin_card.png`) est la référence de style des cartes ; son sprite (`art_source/ai/assassin.png`) celle des sprites. Nouveau perso = sa carte (1re image) + la référence de style (2e image).
- L'IA rate souvent l'orientation des lames et les prises → toujours vérifier mains et armes.
- Les retouches masquées (`--mask`) sur image transparente échouent (boîte noire) → retouche par référence complète, sans masque.
- Les retouches successives dégradent le détail → toujours repartir de **la meilleure image d'origine**, jamais enchaîner les retouches.
- Sans « whole body with wide margin, ~75 % of image height », les pieds sont coupés.
- Sombre sur sombre = invisible (loup gris foncé) → sol mi-ton + accent clair obligatoire.
- Refusé par le dev : rendu peint, dégradés, grain/texture sur les cartes.

Armes (icônes et armes flottantes : mêmes ids, nouveaux visuels) :

| id | Familles | Équivalent fantasy | Forme lisible |
|---|---|---|---|
| `katana` | blade | Épée longue | Lame droite claire, garde large |
| `shuriken` | blade | Dagues de lancer | 2 dagues croisées, pointe vers l'avant |
| `smg` | gun | Arbalète à répétition | Arbalète trapue, chargeur de carreaux |
| `laser_pistol` | gun + energy | Baguette / arc de lumière (rayon) | Baguette avec cristal cyan |
| `pulse` | energy | Orbe magique | Sphère cristalline lumineuse, anneau |
| `bazooka` | gun + explosive | Fiole-bombe / lance-bombes alchimique | Fiole ronde à mèche, bouchon |

- Projectiles (`WeaponData.projectile_style`) restylés en conséquence : carreaux, dagues, boules arcaniques, fioles ; même lisibilité que l'actuel.
- Même trait noir épais et aplats que les sprites ; cadre de rang en UI, liseré de rang en jeu (D36).

Légal et éthique :
- Divulgation IA Steam acceptée (contenu pré-généré) : à déclarer à la publication (Phase 10).
- Ne jamais copier un design existant (Solo Leveling, Brawlhalla, Brotato, Naruto, Bleach, One Punch Man) : pas de noms d'artistes ni de personnages dans les prompts (seule la mention de style « Brawlhalla » des fichiers de style est admise), pas de costumes ou logos reconnaissables.

## 9. Reference Direction

Hors portée de cette passe — références résumées en section 1
