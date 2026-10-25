# steam_assets — Rift and Run

Suivi des visuels de la page Steam « Coming Soon ». Dimensions vérifiées le 2026-10-12 sur la documentation officielle
(https://partner.steamgames.com/doc/store/assets) ; **re-vérifier avant l'envoi**, Valve les modifie parfois.
Nom du jeu partout : **Rift and Run** (jamais « Turmon »). Aucune capture truquée : les screenshots viennent du vrai jeu
(`capture.tscn --clean`, voir `screenshots/shots.md`).

Statuts : `à créer` · `en cours` · `prêt` · `à vérifier`.

## Sources existantes (ne pas dupliquer : référencer)
| Source | Emplacement | Usage |
|---|---|---|
| Logo (titre doré, fond transparent) | `assets/branding/title.png` | logo de toutes les capsules |
| Emblème portail + héros | `assets/branding/emblem.png` | icônes, capsule verticale |
| Logo vertical / horizontal (emblème + titre) | `assets/branding/logo_vertical.png`, `logo_horizontal.png` | capsules |
| Icône 1024 / 512 / .ico | `assets/branding/icon_*.png`, `icon.ico` | icônes |
| Scène du menu principal (1920x1080, peinte) | `assets/ui/backgrounds/menu.png` | arrière-plan de page, hero |
| Montage et sources du logo | `art_tests/logo/` (non versionné) | `compose.py` |

Illustration maîtresse validée par le dev (2026-10-25) : `source_artwork/key_art_a1.png` (Épéiste de dos devant le portail, boss et horde). **Une image IA par format** (`source_artwork/capsule_<nom>.png`, composée pour le bon ratio, même héroïne, même style), recadrée au ratio exact + logo par `python tools/art/make_steam_capsules.py`. Règles Valve (doc Steamworks « Store Graphical Assets ») : Header, Main et Vertical = même visuel et même logo, aucun texte autre que le titre ; la Small Capsule peut avoir une autre image, le logo doit presque la remplir.

## Capsules de la boutique (`capsules/`)
| Asset | Taille | Format | Statut | Contenu / règle |
|---|---|---|---|---|
| Header Capsule | 920 x 430 | PNG | validé (2026-10-25) (fait par `tools/art/make_steam_capsules.py`) | scène du menu + logo horizontal ; « juste le logo et l'illustration », aucun texte de marketing |
| Small Capsule | 462 x 174 | PNG | validé (2026-10-25) (lisible en 231 x 87) | logo seul (`title.png`) sur fond de scène sombre ; à tester en 231 x 87 |
| Main Capsule | 1232 x 706 | PNG | validé (2026-10-25) | illustration maîtresse : héros, horde sortant du portail, logo |
| Vertical Capsule | 748 x 896 | PNG | validé (2026-10-25) (logo `title.png`, pas `logo_vertical`) | `logo_vertical.png` sur scène verticale |
| Page Background | 1438 x 810 | PNG | validé (2026-10-25) | scène du menu assombrie, sans logo (« subtil, pas trop clair ») |

## Bibliothèque (`library/`)
| Asset | Taille | Format | Statut | Contenu / règle |
|---|---|---|---|---|
| Library Capsule | 600 x 900 | PNG | validé (2026-10-25) | variante verticale de l'illustration maîtresse + logo |
| Library Header | 920 x 430 | PNG | validé (2026-10-25) (copie du Header) | identique au Header Capsule |
| Library Hero | 3840 x 1240 | PNG | validé (2026-10-25) (image 1536 px agrandie 2,5x : un peu douce) | illustration seule, **sans logo** (le logo est posé dessus par Steam) ; garder le sujet au centre-gauche |
| Library Logo | 1280 de large et/ou 720 de haut | PNG transparent | validé (2026-10-25) | `assets/branding/title.png` ou `logo_vertical.png` détouré, marge de sécurité 5 % |

## Icônes (`icons/`)
| Asset | Taille | Format | Statut | Source |
|---|---|---|---|---|
| Shortcut Icon | 256 x 256 | .ico ou .png | à vérifier | `assets/branding/icon.ico` (16-256 px) existe ; héros peu lisible à 16-32 px, version simplifiée possible |
| App Icon | 184 x 184 | .jpg | à valider | emblème sur fond uni (le jpg n'a pas de transparence) |

## Captures d'écran (`screenshots/`)
8 à 10 images, 1920 x 1080 minimum, 16:9. Liste, commandes et statuts : `screenshots/shots.md`.

## Marketing
- Storyboard du trailer (45-75 s) : `trailer/storyboard.md` (à valider).
- 5 idées de GIFs : `gifs/ideas.md`.
- Textes de la page (EN puis FR) : `store_text.md`.

## Règles de composition (extraits)
- Capsules : uniquement le logo et l'illustration, pas de texte de promotion ni de prix, pas de bordure.
- Logo lisible en 231 x 87 : tester chaque capsule réduite.
- Illustration maîtresse = base unique recadrée par format (cohérence), jamais de mélange de styles.
- Les images générées par IA ne remplacent jamais les captures de gameplay ; chaque génération est annoncée et validée par le dev.

Brouillons et anciennes générations (non versionnés) : `art_tests/steam_keyart/` (voir son `LISEZMOI.md`). Ici, seulement les versions validées.
Captures d'écran du vrai jeu : en attente des tests du dev (projectiles, animations d'attaque, tailles).
