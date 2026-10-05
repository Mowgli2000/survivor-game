# Analyse globale avant la démo — 2026-10-05

Analyse faite pendant les playtests du dev, à partir du code, des données et des captures récentes (`art_tests/`). Pas de nouvelle capture, pour ne pas ouvrir de fenêtres pendant le jeu. Les priorités sont des recommandations, à valider par le dev.

## Verdict

**La boucle de jeu est complète et le contenu suffit pour une démo.** On a un combat automatique, 20 vagues, une boutique façon Brotato, des niveaux à rang, des boss à phases, 6 sceaux et lieux, une méta-progression avec récompenses, de la coop locale, une prise en main, de la musique et des sons, deux langues et 403 tests.

Ce qui manque avant de montrer le jeu au public ne relève pas du gameplay de base :
- **l'identité** : nom, logo et titre du menu ;
- **l'animation des persos** (pour la bande-annonce et la page Steam) ;
- **quelques finitions visuelles** ;
- **la sécurité de la sauvegarde** ;
- **un équilibrage validé** ;
- **le « package » démo** : écran wishlist, numéro de version, périmètre réduit.

## Inventaire

| Élément | Quantité | Remarque |
|---|---|---|
| Persos | 7 | Chasseur novice, Assassin, Berserker, Archer, Mage, Contrebandier, Épéiste ; chacun a une règle propre |
| Armes | 27 | 4 familles (Lames, Armes de jet, Magie, Alchimie) ; **4 comportements seulement** : tir de projectiles 17, mêlée en arc 8, rayon 2, frappe du ciel 1 |
| Objets | 59 | Rangs I 12, II 24, III 14, IV 9 ; 17 objets à effets ; 28 contenus verrouillés au départ |
| Cartes de niveau | 10 | Zone, vitesse d'attaque, ramassage, projectiles, perforation, armure, dégâts, critique, déplacement, PV |
| Ennemis | 54 | 6 lieux × 7 monstres par rôle, élites, boss intermédiaires et 6 boss finaux |
| Sceaux et lieux | 6 | Cuivre (donjon) → Astral (antre du dragon) |
| Défis | 28 | Dont 18 récompenses de sceaux |

## Points forts (à mettre en avant)
- **Lisibilité et ressenti** : chiffres de dégâts, tremblement d'écran, coups de mêlée dessinés par arme, projectiles illustrés, un son par arme (volumes égalisés).
- **Profondeur de build** : familles, rangs, fusions, objets à effets, règles de classe.
- **Progression** : chaque sceau change de lieu, de bestiaire et de boss, et débloque une arme et deux objets.
- **Coop locale** : rare dans le genre, à montrer dans la bande-annonce.
- **Solidité technique** : architecture en lot, 403 tests, simulateur d'équilibrage.

## Priorités

**P1** = avant la démo publique · **P2** = avant la sortie · **P3** = plus tard / bonus.

### Gameplay et équilibrage
| Prio | Constat | Proposition |
|---|---|---|
| P1 | Économie v3 et Zone (+200 %) pas encore validées en jeu | Tes playtests, puis le test des plafonds de Zone au simulateur (une nuit) |
| P1 | Mode infini pas remesuré depuis les PV ×160 en vague 20 | Une partie infinie au simulateur, ou le retirer de la démo |
| P2 | **Seulement 10 cartes de niveau** : régénération, vol de vie, esquive, portée, dégâts critiques, chance et récolte ne sortent qu'en boutique | Ajouter 5 à 7 cartes (Brotato propose toutes les stats au niveau) |
| P2 | **4 comportements d'armes pour 27 armes** : beaucoup d'armes « tirent un projectile » | 2 ou 3 comportements de plus : orbite autour du perso, boomerang, aura au sol, chaîne. C'est ce qui rend les builds mémorables |
| P2 | Récapitulatif de fin de partie limité à 4 chiffres (vague, temps, niveau, kills) | Dégâts par arme, build final (armes et objets), meilleur coup. Utile aux joueurs, aux captures d'écran et au streaming |
| P3 | Variantes de boutique « différenciantes » (GDD, phase 5) jamais prototypées | Le jeu tient sans ; à garder comme idée de mise à jour |

### Graphismes
| Prio | Constat | Proposition |
|---|---|---|
| P1 | Le titre affiche encore **« Survivor Game »** | Choisir le nom (piste : Gatebound, à vérifier sur Steam et pour les marques déposées), faire un logo et l'écran titre |
| P1 | **Persos jouables animés seulement par le code** (inclinaison, ondulation, poussière) | **Pilote de pantin articulé** sur un perso : marche, repos, coup reçu, mort (voir plus bas) |
| P2 | **Zones d'explosion** = disque translucide uni avec un contour : style « prototype », en décalage avec le reste | Effet dessiné : onde, éclats, fumée, comme pour les coups de mêlée |
| P2 | **Matériaux** = losanges bleus provisoires | Icône de cristal ou de pièce dans le style des objets, avec un léger scintillement |
| P2 | **Sols** : grandes dalles uniformes, décor surtout au bord de l'arène ; on se lasse vite visuellement | Variantes de dalles, taches, fissures, décor léger au sol par lieu ; arène bien typée par lieu |
| P2 | **Monstres** : pas d'animation de mort ni de coup reçu (flash et effet seulement) | Mort en « pop » de morceaux ou dissolution par lieu ; écrasement au coup reçu (coût faible, tout en lot) |
| P2 | Aura au passage de niveau et phase enragée du boss final : prévues, pas faites | À faire pour la bande-annonce |
| P2 | Icônes d'armes du HUD (en bas) très petites | Les agrandir un peu, ou les grouper |

### Interface et expérience joueur
| Prio | Constat | Proposition |
|---|---|---|
| P1 | Pas de numéro de version à l'écran | Version dans un coin du menu et dans les rapports de bug |
| P1 | Pas d'écran « Ajoute à ta liste de souhaits » | Écran de fin de démo avec un bouton vers la page Steam |
| P2 | Paramètres : pas de remappage des touches ni de choix de résolution | Remappage clavier et manette, résolution et mode fenêtre |
| P2 | Pas d'écran de crédits | Crédits : sons et musiques CC0, polices, outils, déclaration de l'IA |
| P2 | Manette vue en double avec DS4Windows (côté PC) | Protection en jeu prévue avec `Platform` (phase 10) |
| P3 | 2 langues (anglais, français) | Allemand, espagnol, portugais du Brésil, chinois simplifié : les gros marchés du genre |

### Technique
| Prio | Constat | Proposition |
|---|---|---|
| P1 | **Sauvegarde non atomique** : `save_profile` écrit directement dans `profile.json`. Un plantage ou une coupure pendant l'écriture peut **effacer le profil** | Écrire dans un fichier temporaire, puis renommer, et garder une copie de secours (risque n°7 du GDD). Petit chantier |
| P1 | Stress test **~80 FPS** à la dernière mesure, sous le seuil de 100 (machine lente ce jour-là) | Remesurer, machine au repos ; si ça reste sous 100, profiler (Zone +200 % comprise) |
| P2 | Pas de rapport de plantage | Journal local et lien « envoyer le rapport » (phase 12) |
| P2 | Steam pas intégré (succès, cloud, Steam Deck) | Phase 10 ; pas nécessaire pour la démo |

### Steam, marketing, juridique
| Prio | Constat | Proposition |
|---|---|---|
| P1 | **Page Steam pas ouverte** : les wishlists mettent des mois à monter | Compte Steamworks (100 $), capsules, 5 captures ou plus, trailer court, description, **déclaration de l'IA** |
| P1 | Bande-annonce : il faut des persos animés et des effets lisibles | Après le pilote d'animation et les P2 visuels les moins chers (explosions, matériaux) |
| P2 | Proximité avec Solo Leveling | Garder les archétypes, jamais les noms, les rangs E-S ou les designs |
| P2 | Licences | Tout est en CC0 (`assets/CREDITS.md`) ; ne garder que ce type de source |

## Pilote d'animation (pour la bande-annonce)

Il existe une planche de pièces par perso (`art_source/ai/rig/*_parts.png`) : tête, buste, jupe ou bassin, bras en 2 morceaux, jambes en 2 morceaux, sur un fond sombre avec un halo.

Plan proposé :
1. **Pilote sur l'Épéiste** : planche la plus nette, et c'est la classe mêlée de la vidéo.
2. Découper les pièces : retirer le fond et le halo, puis fixer les pivots (épaules, coudes, hanches, genoux, cou).
3. **Pantin dans Godot** : une petite hiérarchie de sprites (un seul joueur à l'écran, donc aucun coût en performance), animée **par le code**, comme les animations actuelles du perso.
   - Repos : respiration, cheveux qui ondulent.
   - Marche : jambes et bras en balancier, rebond.
   - Coup reçu : recul et flash.
   - Mort : chute.
   - Toutes réglables sans outil externe.
4. Comparer en capture avec le sprite actuel, à la taille réelle en jeu : le pantin doit rester lisible à ~100 px.
5. Si le rendu plaît : les 6 autres persos. Sinon : planches refaites, ou un animateur freelance.

## Périmètre de démo proposé
- **3 ou 4 persos** : Chasseur novice, Épéiste, Archer (+ Mage).
- **Sceaux Cuivre et Fer** : 2 lieux, 2 boss finaux. Les autres sceaux sont visibles mais « dans le jeu complet ».
- Partie complète en 20 vagues, coop locale, déblocages actifs dans la démo.
- Pas de mode infini (ou limité).
- Écran wishlist à la fin, numéro de version, lien de retour (formulaire).
- Techniquement : une option « démo » dans les données (contenu autorisé), pas un second projet.

## Ordre de travail recommandé
1. **Pilote d'animation** (Épéiste), en parallèle des playtests.
2. **P1 techniques rapides** : sauvegarde atomique, numéro de version, mesure des FPS.
3. **Nom et logo**, puis page Steam (captures et trailer après les points 1 et 4).
4. **P2 visuels les moins chers** : explosions, matériaux, mort des monstres, aura de niveau.
5. Option démo et écran wishlist, puis Steam Next Fest.
6. Ensuite les P2 de gameplay (cartes de niveau, nouveaux comportements d'armes, récapitulatif), les paramètres complets, Steam, la sortie.
