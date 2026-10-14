# Équilibrage des armes — 2026-10-14

Remplace la note « Lame runique intacte » de `equilibrage-armes-2026-10-11.md` : la Lame runique est rééquilibrée comme les autres.

## Règles retenues (validées par le dev)
- Cibles de victoire inchangées : dangers 1 à 6 = 65-75 / 55-65 / 45-55 / 35-45 / 25-35 / 15-25 %.
- Le trio Arc céleste, Lames d'ombre, Faux de guerre reste légèrement au-dessus (environ +35 % de sa catégorie). L'Arc céleste reste n°1.
- Comparaison par catégorie (mêlée 1,0 · zone/explosif 1,1 · distance 1,2) : une arme à distance touche plus tôt, c'est normal qu'elle fasse plus de dégâts.
- Une arme plus faible dans certains builds est normale ; on vise une bande, pas l'égalité.

## Méthode
Trois mesures, aucune ne suffit seule :
1. **Test en build mixte** (`policy ref`, 2 parties par arme) : l'arme testée (3 exemplaires, rang III) + 3 armes de référence. Biaisé : les armes qui touchent en premier volent les kills aux autres (saturation). Abandonné comme mesure principale.
2. **Stand de tir** (`--dummy 8 --dummy-hp 12`, policy `range`) : une seule arme, rang III, sans objet, ennemis à 12x les PV, joueur immortel ; dégâts par vague (vagues 6-8). Sans partage des kills. Bruit élevé entre parties (écarts de 10 à 150 %), donc médiane de 3 parties.
3. **Modèle rapide** (`balance_model.tscn`) : DPS affiché x nombre de cibles touchées dans une foule. Ne voit pas les statuts, les rebonds ni le placement.

Les corrections viennent de la moyenne géométrique des deux dernières mesures, amorties (exposant 0,6, facteur limité à 0,5-2,5). Passes 4 à 6.

## Valeurs finales (dégâts de base du rang I, délai en secondes)
| arme | dégâts | délai |
|---|---|---|
| alchemy_cannon | 23.0 | 1.9 |
| bazooka | 18.2 | 2.2 |
| bomb | 36.5 | 2.0 |
| celestial_bow | 22.0 | 0.8 |
| fire_flask | 9.5 | 1.2 |
| fire_staff | 22.0 | 0.95 |
| frost_flask | 15.1 | 1.2 |
| frost_scepter | 13.0 | 0.8 |
| heavy_axe | 25.9 | 1.9 |
| heavy_crossbow | 48.4 | 1.8 |
| javelins | 55.0 | 1.3 |
| katana | 6.5 | 1.1 |
| laser_pistol | 22.0 | 1.0 |
| lightning_staff | 27.2 | 1.0 |
| longbow | 37.0 | 1.0 |
| meteor_grimoire | 24.2 | 1.6 |
| pulse | 37.9 | 2.4 |
| rapier | 18.6 | 0.45 |
| runic_blade | 25.7 | 1.0 |
| scythe | 27.4 | 1.5 |
| shadow_blades | 32.0 | 1.0 |
| shuriken | 37.0 | 0.9 |
| sling | 35.4 | 0.5 |
| smg | 11.4 | 0.19 |
| spear | 22.6 | 0.75 |
| steel_katana | 26.8 | 0.85 |
| venom_fangs | 8.3 | 0.32 |
| warhammer | 36.7 | 2.2 |

La SMG a aussi un délai passé de 0,12 à 0,19 s (passe 1). La Grenade à fragments est retirée du jeu sur `develop` (récompense remplacée par le Grimoire de météores).

## Limites
- Le bruit entre parties est fort ; les armes sont dans une bande d'environ ±30 % de leur cible, pas plus précis.
- La Fronde et le Bâton de foudre ont réagi peu aux hausses de dégâts (cadence, portée ou vitesse des projectiles à revoir si le playtest les trouve faibles).
- La Lance meurt à la vague 1 dans une partie sur deux (début de partie danger 6 avec une seule arme) : non mesurable par le test mixte.
- Mesures faites avec le Héros au danger 6 ; les autres personnages sont traités à l'étape suivante.
- Les dégâts absolus servent de base à l'étape ennemis/dangers, qui réglera les taux de victoire.
