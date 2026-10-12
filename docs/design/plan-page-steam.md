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
Partis du logo fixé (`assets/branding/`) et du fond du menu (`assets/ui/backgrounds/menu.png`, 1920×1080).

| Visuel | Format (à vérifier) | Contenu | Source |
|---|---|---|---|
| Capsule d'en-tête | 460×215 | Logo + héros/portail | `logo_horizontal.png` sur fond de scène |
| Petite capsule | 231×87 | Logo seul, lisible | `title.png` |
| Capsule principale | 616×353 | Logo + scène + héros | montage |
| Capsule verticale | 374×448 | Logo vertical | `logo_vertical.png` |
| Bannière de la page | 1438×810 (hero) | Scène d'ambiance | fond du menu sans panneau |
| Logo de bibliothèque | PNG transparent, ~1280 px | Logo seul | `title.png` / vertical |
| Arrière-plan de la page | 1438×810 | Scène assombrie | fond du menu |
| Icône | 32/256 px + .ico | Emblème portail | `assets/branding/icon.ico` |
| Captures d'écran | 1920×1080, au moins 5 | Voir §3 | `capture.tscn` |

Ordre : capsule principale et en-tête d'abord (c'est ce que les joueurs voient dans les listes), puis le reste.
Les montages de capsule se font par script Pillow (comme `art_tests/logo/compose.py`), les illustrations d'ambiance par IA
(annoncer et faire valider chaque génération avant l'appel).

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
Outil : `capture.tscn -- --time=20 --out=<png> [--stress] [--shop] [--levelup] [--boss=...]` (voir CLAUDE.md).

## 4. Bande-annonce (30 à 60 s)
Pas de voix. Structure : accroche 3 s (portail qui s'ouvre) → combat dense 15 s → boutique et choix 10 s → boss 10 s →
logo et « Wishlist now » 5 s. Capturer des vidéos 1080p/60 du vrai jeu (OBS), avec les armes peintes. Musique du menu ou
d'un morceau libre de droits. Matériel déjà disponible : effets peints, boss, stress test avec horde.

## 5. Texte de la page (anglais d'abord, puis français)
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
