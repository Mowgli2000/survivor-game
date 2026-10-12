# Plan de la page Steam « Coming Soon » — Rift and Run

Objectif : ouvrir une page publique tôt pour accumuler des wishlists (elles mettent des mois à venir). La démo viendra
plus tard (application Steam séparée, rattachée à la page). Roadmap : phase 6b « Vertical slice + page Steam »
(`docs/design/gdd.md`), puis phases 10-12.

> **À vérifier avant de produire quoi que ce soit** : les formats d'images, les frais et les délais ci-dessous viennent
> de la mémoire de Claude, pas de la documentation actuelle. Les confirmer sur la doc Steamworks (partner.steamgames.com,
> « Store Graphical Assets » et « Release process »).

## 1. Compte et administratif (à lancer en premier, en parallèle de tout le reste)
- [ ] Compte Steamworks (partenaire) : identité, banque, fiscalité (formulaires fiscaux selon le pays).
- [ ] Frais d'application (environ 100 $ par jeu, remboursables selon seuil de ventes : à vérifier).
- [ ] Créer l'application « Rift and Run » : on obtient l'App ID. **Aucun code Steam dans le jeu avant la phase 10** (CLAUDE.md).
- [ ] Choisir le nom de l'éditeur/développeur affiché sur la page (nom du dev ou studio).
- [ ] Vérifier le nom : recherche directe sur Steam, itch.io, base de marques de l'EUIPO (« Rift Runner » existe en plus petits jeux).
- [ ] Délai connu à vérifier : une page doit en général être publique un certain temps (environ 2 semaines) avant la sortie ; la revue de la page par Valve prend quelques jours.

## 2. Visuels à produire
Tailles **officielles vérifiées le 2026-10-12** (https://partner.steamgames.com/doc/store/assets) ; suivi détaillé, statuts et
règles de composition dans `steam_assets/README.md`. Partis du logo fixé (`assets/branding/`) et du fond du menu
(`assets/ui/backgrounds/menu.png`, 1920x1080).

| Visuel | Taille | Contenu |
|---|---|---|
| Header Capsule | 920 x 430 | logo horizontal + scène |
| Small Capsule | 462 x 174 | logo seul (tester en 231 x 87) |
| Main Capsule | 1232 x 706 | illustration maîtresse + logo |
| Vertical Capsule | 748 x 896 | logo vertical |
| Page Background | 1438 x 810 | scène assombrie, sans logo |
| Library Capsule | 600 x 900 | variante verticale |
| Library Header | 920 x 430 | = Header Capsule |
| Library Hero | 3840 x 1240 | illustration sans logo |
| Library Logo | 1280 de large et/ou 720 de haut, PNG transparent | `title.png` |
| Shortcut Icon | 256 x 256 (.ico/.png) | `assets/branding/icon.ico` |
| App Icon | 184 x 184 (.jpg) | emblème sur fond uni |
| Captures | 1920 x 1080 min, 16:9 | voir §3 |

Ordre : capsules principale et d'en-tête d'abord (liste et recherche), puis le reste. Les capsules ne contiennent que le logo et
l'illustration. Les montages se font par script Pillow (`art_tests/logo/compose.py`), les illustrations d'ambiance par IA
(chaque génération annoncée et validée avant l'appel).

## 3. Captures d'écran (5 à 8)
Sans interface en trop, 16:9, avec action lisible. Chaque capture doit montrer le style et une idée du jeu :
1. Combat avec horde et armes peintes (le plus fort visuellement).
2. Boss (Shogun / Chevalier démon) avec sa barre.
3. Boutique entre deux vagues (pilier du design).
4. Choix de niveau supérieur (cartes avec icônes).
5. Sélection de personnage et des armes.
6. Écran des sceaux (six dangers, portail coloré).
7. Coop locale à deux.
8. Menu principal (nouveau fond).
Outil : `capture.tscn -- --time=<s> --clean --out=<png> [options]` avec `--resolution 1920x1080` (`--clean` retire la surcouche de debug et les barres de manette). Liste complète des 10 prises et commandes : `steam_assets/screenshots/shots.md`.

## 4. Bande-annonce (45 à 75 s, voir `steam_assets/trailer/storyboard.md`)
Pas de voix. Structure : accroche 3 s (portail qui s'ouvre) → combat dense 15 s → boutique et choix 10 s → boss 10 s →
logo et « Wishlist now » 5 s. Capturer des vidéos 1080p/60 du vrai jeu (OBS), avec les armes peintes. Musique du menu ou
d'un morceau libre de droits. Matériel déjà disponible : effets peints, boss, stress test avec horde.

## 5. Texte de la page (anglais d'abord, puis français : brouillon dans `steam_assets/store_text.md`)
- Courte description (≈300 caractères) : survivor-like roguelite, boutique entre les vagues, attaque automatique,
  chasseurs contre monstres de portails, 6 niveaux de danger, coop locale, mode infini.
- Description longue : points forts en 5-6 blocs avec une image chacun.
- Tags (à choisir) : Roguelite, Action Roguelike, Survivors-like, Bullet Heaven, 2D, Fantasy, Co-op (local), Replay Value.
- Catégories : solo, coop locale partagée (Shared/Split Screen Co-op), manette complète.
- Langues : anglais et français au lancement (le jeu a `en`/`fr` dans `localization/strings.csv`).
- Classification d'âge (questionnaire IARC) : violence de fantasy, pas de sang explicite à vérifier.
- Points à ne pas promettre : date de sortie ferme, contenu non fait.

## 6. Ce que le jeu doit avoir avant d'ouvrir la page (peu)
- Nom et logo en jeu : fait (menu). Reste à vérifier les autres écrans (titre de fenêtre `config/name` est déjà « Rift and Run »).
- Numéro de version à l'écran : fait (`v0.9.0`).
- Aucun contenu placeholder visible dans les captures (armes TEMP de l'Archère à retirer avant les captures finales).

## 7. Démo (plus tard)
Application séparée dans Steamworks (« Add demo »), rattachée à la page. Contenu : 3-4 persos, sceaux Cuivre et Fer
(`docs/design/analyse-avant-demo-2026-10-05.md`). Cible : Steam Next Fest. Pas à faire pour la page « Coming Soon ».

## 8. Calendrier proposé
| Semaine | Travail | Dépend de |
|---|---|---|
| 1 | Compte Steamworks, nom vérifié, captures d'écran, capsules (montage) | logo fait |
| 2 | Bande-annonce brute, textes EN/FR, bannière et arrière-plan | captures |
| 3 | Remplir la page, envoyer pour revue, corriger les retours | tous les visuels |
| 4+ | Page publique, partage (Reddit, Discord, réseaux), suite du jeu | revue acceptée |
| Plus tard | Démo, Next Fest, phase 10 (GodotSteam), succès | — |

## 9. Risques
- Pas de visuel qui se détache : tester les capsules en 231×87 et 460×215 avant d'envoyer.
- Wishlists lentes : publier la page tôt, poster des GIF de combat et la bande-annonce régulièrement.
- Contenu temporaire visible : retirer les armes `TEMP_PLAYTEST_*` de l'Archère et de l'Épéiste avant toute capture finale.
- Nom proche de « Rift Runner » : recherche de marque avant de dépenser sur les visuels.
