# ADR 0008 — Audio : autoload `Audio`, bus et anti-saturation

**Statut :** accepté (2026-10-03) — autoload prévu dans `CLAUDE.md`, accepté par le dev

## Résumé
Un autoload `Audio` joue la musique et les effets sonores. Les systèmes l'appellent avec le son à jouer. Des règles anti-saturation évitent qu'une horde de 500 ennemis déclenche des centaines de sons par image.

## Décisions
1. **Bus** (`default_bus_layout.tres`) : Master, Music, SFX. Un limiteur sur SFX évite la saturation. Ces bus serviront aux réglages de volume.
2. **`Audio`** (`src/audio/audio.gd`) : un lecteur de musique (boucle) et un pool de 32 lecteurs d'effets, actifs pendant les pauses (boutique, level-up). `play(stream, volume_db, pitch_variation)` refuse un son si le même a été joué il y a moins de 35 ms ou s'il tourne déjà 4 fois. Légère variation de hauteur aléatoire (hors du RNG de la partie : n'affecte pas le rejeu).
3. **Catalogue** `Sounds` (`src/audio/sounds.gd`) : constantes préchargées. Le son de tir de chaque arme est une donnée : `WeaponData.fire_sound` et `fire_volume_db`.
4. **Coût en horde** : `EnemyManager` (coups, morts) et `PickupManager` (ramassages) ne demandent qu'un son par image physique. Mesure : environ 0,5 ms de physique en plus au stress test (171-175 FPS de moyenne).
5. **Assets** : Kenney (CC0) pour les effets, « Synthwave House Loop » de Fupi (CC0) pour la musique. Crédits dans `assets/CREDITS.md`. Les packs bruts vont dans `assets_src/`, qui est ignoré par git et par Godot (`.gdignore`). Seuls les fichiers retenus sont copiés dans `assets/`.

## Alternatives écartées
- **`AudioStreamPlayer2D` positionnels** : la caméra suit le joueur dans une arène fermée, le son positionnel n'apporte presque rien et coûte plus cher.
- **EventBus + écouteur audio** : un niveau d'indirection de plus sans besoin actuel. À reconsidérer si plusieurs systèmes doivent réagir aux mêmes événements.
