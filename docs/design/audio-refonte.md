# Refonte audio (ElevenLabs) — inventaire et plan

Décision du dev (2026-10-18) : refaire tout l'audio du jeu avec ElevenLabs (compte Starter, clé dans la variable
d'environnement utilisateur `ELEVENLABS_API_KEY`, permissions Sound Effects + Music, pas `user_read`).

## Règles
- Un seul essai par son (`--n 1` côté images ; ici un seul tirage), un deuxième seulement si le premier est faux.
- Annoncer et faire valider avant tout appel payant. Compter les crédits dans l'outil (pas de `user_read`).
- Musique : **ne pas générer** avant d'avoir lu les conditions d'Eleven Music pour un jeu commercial (les conditions
  v1 interdisent les jeux vidéo sur Starter sans accord écrit ; la page tarifs dit « licence commerciale »).
  Garder la preuve (capture ou mail) dans `docs/`.
- Chaque son remplacé garde le même nom de constante dans `Sounds` (pas de renommage d'ID).

## Existant (3 musiques, 76 effets)
- Musique : menu (`menu_dark_shrine.ogg`), combat (`battle_theme_a.mp3`), boss (`boss_battle_rpg.mp3`). Libres de droits,
  empruntées à OpenGameArt.
- Armes (25) : un son de tir par arme dans `assets/audio/sfx/weapons/`.
- Combat (19) : coups, morts (5 « thuds », 6 « pops »), critique, joueur touché, battement de coeur, avertissement,
  alerte boss, tic, mèche, tir ennemi.
- Interface et jeu (32) : boutique (achat, vente, relance, verrou, fusion, erreur), clics, survol, début/fin de vague,
  victoire, défaite, montée de niveau, portail, flammes, éclairs, grondement, ramassages.
- Aucun son propre pour : les attaques des 6 boss finaux, les mini-boss, les projectiles ennemis (un seul tir
  commun), les impacts par arme, les pas, l'ambiance par lieu, l'entrée des boss, les changements de phase.

## À créer en plus (proposition)
1. Boss : une alerte d'entrée, un son de changement de phase, un son par famille d'attaque (frappe au sol, onde,
   faisceau, projectiles, invocation de zone, vol, souffle), mort du boss.
2. Ennemis : un tir par famille (flèche, magie, venin), mort d'élite et de mini-boss, kamikaze.
3. Impacts d'armes : feu, glace, éclair, explosion (petite, grande), poison.
4. Interface : titre, validation de défi, déblocage, carte de nouveau fond.
5. Ambiance : une boucle par lieu (6) — après décision sur la musique.

## Étapes
1. Liste source `tools/audio/sound_list.json` (id, description anglaise, durée, volume relatif).
2. Outil `tools/audio/gen_sfx.py` (clé lue dans l'environnement, repli sur le registre Windows ; écrit dans
   `art_tests/audio/` ; compteur de crédits).
3. Essai sur 5 sons, écoute avec le dev, réglage du style des descriptions.
4. Production par familles, normalisation du volume, remplacement dans `assets/audio/`, mise à jour de `Sounds`,
   écoute en jeu.
5. Musique : après les conditions.
