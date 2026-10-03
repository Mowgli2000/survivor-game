# Méta-progression, ennemis, boss, modes — proposition à trancher

**Date :** 2026-10-03 · **Statut :** proposition, à discuter avec le dev
**But :** décider ensemble ce qui se débloque, comment, avec quels ennemis, boss et modes, puis planifier les étapes 6 (boss), 7 (méta-progression) et 8 (contenu).

Chaque section donne : ce que fait **Brotato** (notre référence, D22) et pourquoi ça marche, les options, **ma recommandation**, le coût, et les **questions** (numérotées Q1, Q2…). Les réponses peuvent être courtes (« Q3 : B »).

---

## 0. Principe directeur : que gagne-t-on d'une partie à l'autre ?

| Option | Description | Exemples | Pour | Contre |
|---|---|---|---|---|
| **A. Horizontale** | On débloque de la **variété** (persos, armes, objets, difficultés), jamais de puissance permanente | Brotato, Slay the Spire | Chaque partie reste un vrai défi ; l'équilibrage reste maîtrisable ; la rejouabilité vient des combinaisons | Moins de sentiment de « je deviens plus fort » entre les parties |
| **B. Verticale** | Une monnaie gagnée en partie achète des **bonus permanents** (+5 % dégâts, +10 PV…) | Vampire Survivors, Hades (en partie) | Récompense constante, progression même en perdant | Les premières parties deviennent faciles, il faut sur-équilibrer ; risque de « farm » |
| **C. Horizontale + petit confort** | A, plus quelques bonus **non puissants** (ex. relance gratuite au début, choix du perso de départ) | Brotato (léger), Halls of Torment | Garde l'intégrité de A avec un peu de récompense | Un peu plus de travail |

**Recommandation : A** (déjà noté dans le statut : « préférer débloquer du contenu »). C'est le modèle de Brotato, il colle à notre boutique (la puissance vient de la partie, pas du compte).

- **Q1.** Méta horizontale (A), verticale (B) ou mixte (C) ?

---

## 1. Ce qui se débloque

| Contenu | Brotato | Proposition |
|---|---|---|
| **Personnages** | ~45, l'essentiel de la méta | **Oui, cœur de la méta** (voir §3) |
| **Armes** | Débloquées par des défis | Oui : on démarre avec 6 armes, ~10-14 à terme |
| **Objets** | Débloqués par des défis | Oui : ~60 % disponibles d'entrée, le reste à débloquer |
| **Niveaux de difficulté** | « Danger 0 à 5 », par personnage | Oui (voir §4) |
| **Modes** | Mode infini après une victoire | Oui (voir §7) |
| **Cartes / arènes** | Une seule arène | Plus tard (étape 8), 1 arène suffit pour la démo |
| **Cosmétiques** | Non | Non pour l'instant |

- **Q2.** Cette liste te convient ? Envie d'ajouter des arènes différentes dès le début ?

---

## 2. Comment on débloque

| Option | Description | Pour | Contre |
|---|---|---|---|
| **A. Défis** | Chaque déblocage a une condition : « Gagner avec le Rōnin », « Tuer 5 000 ennemis », « Finir une partie avec 6 lames » | Donne des objectifs variés, pousse à essayer des builds ; se transforme directement en **succès Steam** | Il faut écrire et tester les conditions |
| **B. Monnaie méta** | On gagne des « éclats » à chaque partie, on achète les déblocages dans un menu | Simple, progression garantie | Moins d'objectifs intéressants ; « farm » |
| **C. Mixte** | Les persos par défis, le reste en monnaie | Les deux sensations | Deux systèmes à équilibrer |

**Recommandation : A (défis)**, comme Brotato. Exemples : chaque personnage débloque un autre perso ou une arme quand on gagne avec lui ; quelques défis transversaux (« Tuer 10 000 ennemis », « Gagner sans acheter d'arme », « Atteindre 100 % de critique »).

- **Q3.** Défis (A), monnaie (B) ou mixte (C) ?

---

## 3. Personnages

**Brotato :** un personnage = des **modificateurs** (bonus et malus), une **règle unique** qui change la façon de jouer, et un **choix d'arme de départ**. Exemple : « Chasseur : +portée, −PV, les armes à feu font plus de dégâts » ; « Fou : ne peut avoir que des armes de mêlée ».

**Proposition : 6 personnages pour la démo, 15-20 à terme**, dans le thème cyber-ninja néon :

| Perso (idées) | Règle / style | Débloqué par |
|---|---|---|
| **Drifter** (actuel) | Équilibré, aucun malus | Dispo |
| **Rōnin** | +dégâts des lames, −portée ; ne commence qu'avec une lame | Gagner avec Drifter |
| **Gunslinger** | +portée et vitesse d'attaque des armes à feu, −armure | Tuer 2 000 ennemis avec des armes à feu |
| **Technomancien** | Les statuts (brûlure, électrocution) sont plus forts ; −dégâts bruts | Infliger 500 brûlures |
| **Marchand** | +récolte et réduction en boutique, −dégâts | Avoir 300 matériaux en même temps |
| **Berserker** | Plus il perd de PV, plus il frappe fort ; pas de régénération | Gagner une partie en dessous de 20 % de PV à la fin |

Côté technique : un perso = une ressource `CharacterData` (déjà existante : stats, arme de départ) + des **règles** réutilisant les effets d'objets de l'étape B. Un **écran de sélection** du perso avant la partie (avec la difficulté).

- **Q4.** Ce style de personnages (règle unique + bonus/malus) te va ? Des idées de persos à toi ?
- **Q5.** Choix de l'arme de départ au lancement (comme Brotato), ou arme fixe par perso ?

---

## 4. Niveaux de difficulté

**Brotato :** « Danger 0 à 5 », débloqués **par personnage** en gagnant au niveau précédent. Chaque niveau ajoute : plus d'élites, plus de PV et de dégâts ennemis, et au niveau 5 **deux boss** à la vague 20.

**Proposition :** 6 niveaux (0 à 5), débloqués par personnage :

| Niveau | Ajout (cumulatif) |
|---|---|
| 0 | Partie actuelle |
| 1 | Élites plus fréquentes |
| 2 | Ennemis +15 % PV et dégâts |
| 3 | Nouveaux ennemis plus tôt, hordes plus grandes |
| 4 | Ennemis +30 % PV et dégâts, boss renforcé |
| 5 | Deux boss en vague 20 |

C'est presque gratuit techniquement : un **multiplicateur** sur nos courbes de vague existantes + des événements en plus. C'est aussi la principale **rejouabilité** à long terme (gagner chaque perso en Danger 5).

- **Q6.** Difficultés par personnage (Brotato) ou un niveau global pour tout le compte ?

---

## 5. Ennemis : patterns et nombre

**Aujourd'hui :** 4 types (grunt qui fonce, chauve-souris rapide, tireur à distance, tank), élites dorées, hordes. Tous foncent ou tirent : peu de variété de comportements.

**Brotato :** ~20 comportements, chacun oblige à réagir autrement : fonceurs, **chargeurs** (s'arrêtent puis foncent en ligne droite), tireurs, **pondeurs** (arbres/œufs immobiles qui libèrent des ennemis si on ne les tue pas), **soigneurs**, **kamikazes** qui explosent, **ennemis-butin** qui fuient et lâchent une caisse.

**Proposition : ~10 types pour la démo** (6 nouveaux), un comportement nouveau = une petite « strategy » réutilisable (comme les armes) :

| Nouveau type | Comportement | Ce que ça demande au joueur |
|---|---|---|
| **Chargeur** | S'arrête, prévient (clignote), fonce en ligne droite | Esquiver latéralement |
| **Kamikaze** | Court vers le joueur et explose | Le tuer à distance |
| **Pondeur** | Immobile, libère des ennemis toutes les X s | Prioriser une cible |
| **Soigneur** | Soigne les ennemis proches | Prioriser une cible |
| **Bouclier** | Protège les ennemis devant lui | Changer d'angle |
| **Coffre fuyard** | Fuit, lâche des matériaux / un objet si tué | Prise de risque |

**Nombre d'ennemis :** aujourd'hui jusqu'à **650 à l'écran** (D41), en paquets. Proposition : garder 650 (≈ 120 FPS) ; la difficulté monte surtout par la **variété** et les **hordes**, pas seulement par le nombre.

- **Q7.** Ces comportements te plaisent ? Lesquels en priorité (3 premiers) ?
- **Q8.** Nombre d'ennemis : 650 nous suffit, ou tu veux viser plus (demanderait l'optimisation du rendu, ~1-2 jours) ?

---

## 6. Boss

**Brotato :** des **élites/mini-boss** aux vagues 11-12, un **boss** en vague 20 tiré au hasard parmi quelques-uns ; tuer le boss gagne la partie.

**Proposition :**
- **Mini-boss en vague 10** (un élite avec une attaque spéciale) : casse la monotonie au milieu de la partie.
- **Boss final en vague 20**, **2 ou 3 boss différents** tirés au hasard (rejouabilité), chacun avec **3 phases** (change d'attaque à 66 % et 33 % de PV) :
  - *Shogun* : charges en ligne + vagues de lames en éventail ;
  - *Oni mécanique* : invoque des vagues d'ennemis + zones au sol qui explosent ;
  - *Tisseuse néon* : laisse des traînées dangereuses, projectiles en spirale.
- **Barre de vie de boss** en haut de l'écran, nom du boss, **coffre de récompense** (un objet rare) pour le mini-boss.
- Techniquement : un boss = des **phases** et des **attaques** décrites en données (`.tres`), comme les vagues ; l'arène n'a pas besoin de changer.

- **Q9.** Mini-boss en vague 10 + boss final aléatoire parmi 2-3 : OK ? Un boss préféré à faire en premier ?

---

## 7. Mode infini

**Brotato :** après une **victoire**, on peut **continuer** au-delà de la vague 20 : les ennemis deviennent très forts très vite ; on joue pour le record.

**Proposition :** oui, c'est **peu coûteux** :
- après la victoire : bouton « Continuer en infini » ;
- vagues de 60 s, PV / dégâts / nombre qui continuent de monter, un boss toutes les 10 vagues ;
- record (vague atteinte) sauvegardé par perso ; plus tard un **classement Steam**.

- **Q10.** Mode infini après victoire (Brotato), mode infini séparé dès le menu, ou pas de mode infini ?

---

## 8. Implémentation technique (pour info)

1. **Sauvegarde** (`SaveService`, prévu dans `CLAUDE.md`) : un fichier JSON **versionné** dans `user://` (jamais de `.tres` chargé depuis `user://`), avec migrations ; contient le **profil** : déblocages, défis réussis, records, niveaux de difficulté gagnés par perso, statistiques cumulées (ennemis tués…), paramètres.
2. **Défis** : une ressource `ChallengeData` (`.tres`) = une condition (type + seuil) + ce qu'elle débloque. Vérifiés à des moments précis (fin de partie, ennemi tué…) via des signaux, sans rien ajouter aux boucles chaudes.
3. **Contenu verrouillé** : armes, objets, persos ont un champ « débloqué par défaut / débloqué par tel défi » ; la boutique et la sélection ne proposent que le contenu débloqué.
4. **Écrans** : menu principal → sélection du perso + difficulté → partie ; écran « Progression / Défis » (liste des défis, réussis ou non).
5. **Steam** (étape 10) : chaque défi peut devenir un **succès Steam** sans travail supplémentaire, via l'autoload `Platform`.

**Ordre de réalisation proposé :**

| Étape | Contenu | Pourquoi dans cet ordre |
|---|---|---|
| **B** (en cours) | Objets à effets + familles d'armes | Les effets d'objets serviront aussi aux règles des persos |
| **C** | Menus (principal, pause, paramètres) | Nécessaires pour la sélection de perso |
| **6** | Mini-boss + 1er boss à phases + barre de boss | Donne une vraie fin à la partie |
| **5b** | Nouveaux ennemis (3 premiers comportements) | Variété avant d'ajouter du contenu |
| **7** | Sauvegarde, défis, déblocages, sélection perso + difficulté | S'appuie sur tout ce qui précède |
| **7b** | Mode infini, niveaux de difficulté | Peu coûteux une fois 7 fait |
| **6b** | Vertical slice (3 persos, ~10 armes, ~30 objets) + page Steam | Démo présentable |

- **Q11.** Cet ordre te convient ? (Variante : avancer la méta (7) avant le boss (6).)

---

## Récapitulatif des questions

| # | Question | Ma reco |
|---|---|---|
| Q1 | Méta horizontale / verticale / mixte | A — horizontale |
| Q2 | Liste de ce qui se débloque | Oui, arènes plus tard |
| Q3 | Déblocage par défis / monnaie / mixte | A — défis |
| Q4 | Persos à règle unique + bonus/malus | Oui |
| Q5 | Arme de départ au choix ou fixe | Au choix (Brotato) |
| Q6 | Difficulté par perso ou globale | Par perso (Brotato) |
| Q7 | Nouveaux comportements d'ennemis, 3 prioritaires | Chargeur, kamikaze, pondeur |
| Q8 | Garder 650 ennemis max | Oui |
| Q9 | Mini-boss vague 10 + boss final aléatoire (2-3) | Oui, Shogun d'abord |
| Q10 | Mode infini après victoire | Oui (après victoire) |
| Q11 | Ordre : B → C → 6 → 5b → 7 → 7b → 6b | Oui |
