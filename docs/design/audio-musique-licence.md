# Musique et ambiance : licence Eleven Music et plan

## Preuve de licence (relevé du 2026-10-18)

Source lue : conditions « Eleven Music model specific terms »
(https://elevenlabs.io/eleven-music-model-specific-terms), résumées via lecture automatique. **Ce n'est pas un avis
juridique ni une confirmation écrite d'ElevenLabs.** Le dev a décidé (2026-10-18) de travailler comme si la licence
commerciale était acquise. À compléter par une capture de la page ou un mail d'ElevenLabs si possible : la page peut
changer.

Points utiles pour Rift and Run (compte Starter, dev solo) :
- Starter : usage commercial permis, pour un individu (le dev solo est dans ce cas). Pas de diffusion de la musique
  seule sur des services de streaming musical. Pas d'attribution obligatoire (l'attribution « Eleven Music » ne
  concerne que le plan gratuit).
- Le dev garde les droits sur ses prompts et sur la musique produite.
- Les jeux « Studio Games » (vendus ou monétisés sur plus d'une plateforme) sont exclus des plans en libre-service.
  Un jeu « Indie Game » n'est pas un Studio Game : revenus cumulés du jeu < 500 000 $ et revenus de l'éditeur
  < 1 000 000 $ sur son dernier exercice (nets de frais et remboursements). Rift and Run (Steam, dev solo) est dans
  ce cas.
- **Risque à connaître** : si le jeu dépasse ces seuils, il faut un plan qui permet les Studio Games dans les
  60 jours (sinon arrêter d'utiliser la musique dans le jeu ; les copies déjà distribuées restent valables).
- Interdit : noms d'artistes, de chansons ou de labels dans les prompts, paroles existantes, bibliothèque de sons
  revendue, imitation de la voix ou du style d'un artiste de façon trompeuse.
- Le dev doit vérifier lui-même la musique avant publication et respecter les règles de divulgation d'IA de Steam
  (déclarer l'usage d'IA dans la fiche).
- Limites mensuelles de génération selon le plan (Starter : environ 30 minutes selon des sources tierces, à
  confirmer sur la page tarifs).

## Existant
Trois morceaux libres de droits (OpenGameArt) : menu, combat, boss (voir `assets/CREDITS.md`). La même musique
de combat sert à tous les lieux. Aucune ambiance par lieu.

## Plan proposé (rien n'est généré)

Musique (boucles propres, sans voix) :
1. Menu : à refaire en dernier si le reste plaît (le morceau actuel peut rester).
2. Combat par lieu, en 6 boucles de 60 à 90 s qui partagent la même palette d'instruments pour que le jeu garde
   une identité : donjon de pierre, donjon orange, temple turquoise, forêt gelée, citadelle rouge, ruche verte.
3. Boss : une boucle plus intense (un seul morceau pour les 6 boss, ou un par boss si le budget le permet).
4. Courts jingles : victoire et défaite (déjà des effets sonores ; à garder tels quels).

Ambiance (couche discrète sous la musique, en boucle) :
- Un fond par lieu : pas de pierre et gouttes (donjon), braises et grincements (donjon orange), vent et cristaux
  (temple), vent glacé (forêt gelée), forge lointaine (citadelle), bourdonnement et substance visqueuse (ruche).
- Bus séparé « Ambiance » avec son propre volume dans les réglages.

Budget estimé (à confirmer) : 6 boucles de combat + 1 boss ≈ 7 à 10 générations de 60 à 90 s. L'ambiance se génère
avec l'API d'effets sonores (même coût par seconde que les armes).

## Étapes avant toute génération
1. Valider la liste des lieux et les ambiances ci-dessus.
2. Décider du style musical (instruments, tempo) et le faire valider sur **une seule** boucle d'essai.
3. Annoncer le coût (minutes de musique et crédits), attendre l'accord du dev.
4. Vérifier que l'API musique est accessible avec la clé (permission Music) et que la boucle est propre.

## Décision (2026-10-19)
Deux essais de `combat_stone` (75 s) : le premier, orchestral et dramatique, trop sérieux ; le second, léger et coloré,
ne plaît pas non plus. **Le dev garde les 3 musiques actuelles (menu, combat, boss) pour tous les lieux, sans
modification.** Aucune autre piste n'est générée. ~2 250 crédits estimés dépensés (essais conservés dans
`art_tests/audio/music/`, hors git). Outil `tools/audio/gen_music.py` et liste `tools/audio/music_list.json` gardés
au cas où. L'ambiance par lieu (bruitages) reste possible si le dev la demande.
