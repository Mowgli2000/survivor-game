# Proposition — identité des classes (à valider)

> Statut : **proposition**, rien n'est codé. Objectif : chaque perso change la façon de jouer (logique Brotato), au lieu de petits bonus de stats.
> Décisions déjà prises (2026-10-04) : identité des classes **avant** le vertical slice 6b ; **2 classes exclusives** seulement (Épéiste mêlée, Archer distance) ; les autres gardent l'accès à toutes les armes.
> Ids inchangés (`drifter`, `hero`, `ronin`, `gunslinger`, `merchant`) : seuls règles, stats et textes changent.

## Vue d'ensemble

| Perso (id) | Style | Règle forte | Difficulté |
|---|---|---|---|
| Chasseur de rang E (`drifter`) | Progression | **Éveil** : les cartes d'amélioration sont 50 % plus fortes | Débutant |
| Assassin (`hero`) | Esquive + critiques | **Pas d'ombre** : chaque esquive donne +critique pendant 2 s ; PV bas | Expert |
| Épéiste (`ronin`) | Mêlée tank | **Mêlée seulement** ; +dégâts, +armure | Intermédiaire |
| Archer (`gunslinger`) | Distance, portée | **Distance seulement** ; la portée bonus donne des dégâts | Intermédiaire |
| Contrebandier (`merchant`) | Économie | **Marché noir** : boutique −20 %, relances +50 %, intérêts | Intermédiaire |
| Mage (nouveau, 6b) | Magie, zones | **Affinité arcanique** : +dégâts par arme Magie, autres armes −25 % | Intermédiaire |
| Berserker (nouveau, 6b) | Risque | **Rage** : +1 % dégâts par % de PV manquants ; pas d'esquive | Expert |

## Détail

### Chasseur de rang E — le novice qui monte (Éveil)
- Fantasme : le chasseur le plus faible qui devient le plus fort (clin d'œil Solo Leveling).
- Règle : **cartes d'amélioration ×1,5** (ex. +10 PV devient +15).
- Stats : aucune bonus de départ ; −10 % de dégâts (il commence faible, finit fort).
- Armes de départ : Épée flamboyante ou Orbe arcanique (au choix, toutes armes ensuite).
- Code : multiplicateur sur `UpgradeOffer.scaled_modifiers()` porté par le perso (nouveau champ `CharacterData.upgrade_scale`). Petit.

### Assassin — l'ombre
- Règle : **Pas d'ombre** : après une esquive, +25 % de chance de critique pendant 2 s.
- Stats : +15 % esquive, +10 % vitesse de déplacement, +50 % dégâts critiques ; **−30 % PV max**.
- Armes de départ : Dagues de lancer (ou Épée flamboyante).
- Code : nouvel `ItemEffect` « bonus temporaire après esquive » (le signal `Player.dodged` existe déjà). Moyen.

### Épéiste — la lame (exclusive mêlée)
- Règle : **ne peut obtenir que des armes de mêlée** (boutique et récompenses filtrées) ; +20 % dégâts, +4 armure, +10 % zone.
- Malus : −25 % portée (déjà en place).
- Armes de départ : Épée flamboyante (+ une 2e arme de mêlée en 6b).
- Code : nouveau champ `CharacterData.allowed_weapon_kind` (toutes / mêlée / distance) lu par `Shop` et les récompenses. Moyen. **Prérequis : au moins 3 armes de mêlée** (6b).

### Archer — l'œil (exclusive distance)
- Règle : **ne peut obtenir que des armes à distance** ; **+3 % de dégâts par 10 % de portée bonus** (effet existant `ConditionalStatEffect`).
- Stats : +25 % portée, +1 perforation ; −3 armure, −10 % PV max.
- Armes de départ : Arbalète à répétition ou Baguette de cristal.
- Code : même filtre que l'Épéiste + effet existant. Petit une fois le filtre fait.

### Contrebandier — le marché noir
- Règle : **prix de la boutique −20 %**, mais **chaque relance coûte +50 %** ; garde les intérêts de fin de vague (+10 %, max 25, existant).
- Stats : +3 récolte ; −10 % dégâts (existant).
- Armes de départ : Orbe arcanique ou Fiole explosive.
- Code : deux multiplicateurs lus par `Shop` (prix, relance). Petit.

### Mage (nouveau, 6b)
- Règle : **+8 % de dégâts par arme de la famille Magie possédée** ; les armes hors Magie font −25 % de dégâts.
- Stats : +15 % zone ; −2 armure.
- Code : effet « par arme de famille » (proche de `WeaponFamilies`). Moyen. Nouvelle arme Magie nécessaire (bâton de feu).

### Berserker (nouveau, 6b)
- Règle : **Rage** : +1 % de dégâts par % de PV manquants ; **esquive bloquée à 0**.
- Stats : +30 PV max, +5 % vol de vie ; −3 armure.
- Code : effet « dégâts selon PV manquants » (nouveau). Moyen. Nouvelle arme : hache à deux mains.

## Ce que ça implique pour 6b
- Armes : au moins **3 mêlée** et **3 distance** viables (aujourd'hui : mêlée = Épée ; distance = Arbalète, Dagues, Baguette, Orbe, Fiole). À ajouter : épée lourde / hache (mêlée), lance (mêlée), bâton de feu (Magie), arc long (distance).
- Objets : quelques objets qui servent chaque style (esquive, mêlée, portée, économie, rage).
- Équilibrage : à vérifier en partie simulée (tests existants) et en playtest.

## Questions au dev
1. Ces règles te parlent ? Une à changer ?
2. Assassin à −30 % PV : trop punitif ? (Brotato a des persos fragiles, ça crée un style « danse »).
3. Ordre d'implémentation : les 5 persos existants d'abord, Mage et Berserker avec 6b ?
