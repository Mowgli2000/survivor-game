extends Node
## Debug tool: draws UI mockups of the "Portal" theme proposal with the real game
## data and art (offers, icons, stats, settings), and saves a screenshot.
## Nothing here is used by the game: it is a throwaway proposal to validate.
## Usage: Godot.exe --path . res://src/debug/ui_mockup.tscn -- --screen=<name> --out=<png>
## Screens: menu_a, menu_b, menu_c1, menu_c2, menu_c3, select, select_seals, shop, pause, settings, levelup

const W := 1920.0
const H := 1080.0
const BG_A := Color("0f0822")
const BG_B := Color("2c1456")
const PANEL := Color("1d1240")
const PANEL_DARK := Color("0e0824")
const BORDER := Color("08051a")
const CYAN := Color("66f2ff")
const VIOLET := Color("b86bff")
const TEXT := Color("eef0ff")
const MUTED := Color("a99fd6")
const GOLD := Color("ffd94d")
const GOOD := Color("73ff8c")
const BAD := Color("ff6673")
const GO := Color("3ed16b")
const BW := 4
const RADIUS := 18

## Class cards: [card file, name, rule, starting weapons, [bonus lines]].
const HEROES: Array[Array] = [
	["gunslinger_card", "Archère", "Armes à distance uniquement. +3 % de dégâts par 10 % de portée bonus.", ["longbow", "smg"],
		["+25 % Portée", "+1 Perforation", "-3 Armure", "-10 % PV max"]],
	["mage_card", "Mage", "Affinité arcanique : +8 % de dégâts par arme de Magie. Autres armes : -25 %.", ["fire_staff", "lightning_staff"],
		["+15 % Zone", "-1 Armure"]],
	["berserker_card", "Berserkeuse", "Rage : +1 % de dégâts par % de PV manquants. Ne peut pas esquiver.", ["heavy_axe", "warhammer"],
		["+30 PV max", "+5 % Vol de vie", "-3 Armure", "-100 % Esquive"]],
	["ronin_card", "Épéiste", "Armes de mêlée uniquement.", ["steel_katana", "spear"],
		["+20 % Dégâts", "+4 Armure", "+10 % Zone", "-25 % Portée"]],
	["assassin_card", "Assassin", "Pas d'ombre : +25 % de critique pendant 2 s après une esquive.", ["rapier", "shuriken"],
		["+15 % Esquive", "+10 % Vitesse", "+50 % Dégâts critiques", "-15 % PV max"]],
	["merchant_card", "Contrebandière", "Marché noir : boutique -20 %, relances +50 %. Intérêts en fin de vague.", ["bomb", "fire_flask"],
		["+3 Récolte", "-10 % Dégâts"]],
	["drifter_card", "Chasseuse novice", "Éveil : les cartes d'amélioration sont 50 % plus fortes.", ["steel_katana", "sling"],
		["-10 % Dégâts"]],
]
const STATS: Array[Array] = [
	["PV max", "100", ""], ["Régénération", "0", ""], ["Armure", "0", ""], ["Vitesse de déplacement", "300", ""],
	["Dégâts", "-10 %", "bad"], ["Vitesse d'attaque", "+0 %", ""], ["Chance de critique", "10 %", "good"],
	["Dégâts critiques", "x2", "good"], ["Vitesse des projectiles", "+0 %", ""], ["Projectiles", "+0", ""],
	["Perforation", "+0", ""], ["Recul", "+0 %", ""], ["Portée", "+0 %", ""], ["Zone", "+20 %", "good"],
	["Portée de ramassage", "200", "good"], ["Esquive", "0 %", ""], ["Vol de vie", "0 %", ""], ["Chance", "+0", ""],
	["Récolte", "+0", ""],
]

var _screen := "menu_a"
var _out := "user://mockup.png"
var _root: Control


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):
			_screen = arg.trim_prefix("--screen=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiTheme.get_theme()
	add_child(_root)
	call("_screen_" + _screen)
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	print("mockup saved: ", ProjectSettings.globalize_path(_out))
	get_tree().quit()


# --- building blocks ---------------------------------------------------------------

func _style(fill: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	return sb


func _panel(rect: Rect2, fill: Color = PANEL, border: Color = BORDER, bw: int = BW, radius: int = RADIUS) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", _style(fill, border, bw, radius))
	_root.add_child(p)
	return p


func _label(text: String, size: int, color: Color, pos: Vector2, width: float = 0.0,
		align: int = HORIZONTAL_ALIGNMENT_LEFT, display: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	if width > 0.0:
		l.custom_minimum_size.x = width
		l.size.x = width
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if display:
		l.add_theme_font_override("font", UiTheme.BANGERS)
		l.add_theme_constant_override("outline_size", 10)
		l.add_theme_color_override("font_outline_color", BORDER)
	_root.add_child(l)
	if width > 0.0:
		l.size.x = width
	return l


func _image(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if img != null else null


func _tex(path: String, rect: Rect2, region: Rect2 = Rect2(), tint: Color = Color.WHITE) -> TextureRect:
	var r := TextureRect.new()
	var tex := _image(path)
	if region.size != Vector2.ZERO:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = region
		tex = at
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture = tex
	r.position = rect.position
	r.size = rect.size
	r.clip_contents = true
	r.modulate = tint
	_root.add_child(r)
	return r


func _card_path(index: int) -> String:
	return "res://assets/characters/cards/%s.png" % HEROES[index][0]


func _weapon_icon(id: String) -> String:
	return "res://assets/icons/weapons/%s.png" % id


func _item_icon(id: String) -> String:
	return "res://assets/icons/items/%s.png" % id


func _ring(center: Vector2, radius: float, color: Color, width: float, start: float = 0.0,
		sweep: float = TAU, fill: Color = Color(0, 0, 0, 0)) -> void:
	var node := Node2D.new()
	node.set_script(preload("res://src/debug/mockup_ring.gd"))
	node.set("center", center)
	node.set("radius", radius)
	node.set("color", color)
	node.set("width", width)
	node.set("start", start)
	node.set("sweep", sweep)
	node.set("fill", fill)
	_root.add_child(node)


func _gradient() -> void:
	var g := Gradient.new()
	g.set_color(0, BG_B)
	g.set_color(1, BG_A)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 8
	gt.height = 256
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var r := TextureRect.new()
	r.texture = gt
	r.size = Vector2(W, H)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	_root.add_child(r)


## Dimmed arena floor behind the in-game screens (shop, pause, settings, level-up).
func _arena_dim() -> void:
	var floor_tex := ColorRect.new()
	floor_tex.color = Color("2a2150")
	floor_tex.size = Vector2(W, H)
	_root.add_child(floor_tex)
	for row in 14:
		for col in 15:
			var off := 70.0 if row % 2 == 1 else 0.0
			var p := Panel.new()
			p.position = Vector2(col * 140.0 - off, row * 80.0)
			p.size = Vector2(136, 76)
			p.add_theme_stylebox_override("panel", _style(Color(0.2, 0.17, 0.36, 0.7), Color(0.12, 0.1, 0.24, 0.8), 2, 6))
			_root.add_child(p)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.12, 0.82)
	dim.size = Vector2(W, H)
	_root.add_child(dim)


func _coin(center: Vector2, radius: float) -> void:
	_ring(center, radius, BORDER, radius * 0.3, 0.0, TAU, GOLD)
	_ring(center, radius * 0.5, Color("c89a1c"), radius * 0.16)


## Pill button; `state`: "normal", "focus" (cyan frame, violet fill, diamond), "disabled", "cta" (green).
func _button(rect: Rect2, text: String, state: String = "normal", size: int = 34, price: int = -1) -> void:
	var fill := PANEL
	var border := BORDER
	var color := TEXT
	match state:
		"focus":
			fill = Color("4a2a86")
			border = CYAN
		"disabled":
			fill = Color(PANEL, 0.6)
			color = Color(MUTED, 0.6)
		"cta":
			fill = Color("7b3ff2")
			border = CYAN
			color = Color.WHITE
	_panel(rect, fill, border, 5 if state in ["focus", "cta"] else BW, int(rect.size.y * 0.5))
	if state == "cta":
		# Lighter top half: a soft sheen so the main action pops.
		_panel(Rect2(rect.position + Vector2(14, 8), Vector2(rect.size.x - 28, rect.size.y * 0.38)), Color(1, 1, 1, 0.14),
			Color(0, 0, 0, 0), 0, int(rect.size.y * 0.2))
	if state == "focus":
		_label("◆", int(size * 0.8), CYAN, rect.position + Vector2(22, rect.size.y * 0.5 - size * 0.62))
	var tx := rect.position + Vector2(0, rect.size.y * 0.5 - size * 0.68)
	if price >= 0:
		_label(text, size, color, tx + Vector2(-34, 0), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_coin(rect.position + Vector2(rect.size.x * 0.5 + text.length() * size * 0.14 + 14, rect.size.y * 0.5), size * 0.36)
		_label(str(price), size, GOLD, rect.position + Vector2(rect.size.x * 0.5 + text.length() * size * 0.14 + 44,
			rect.size.y * 0.5 - size * 0.68))
	else:
		_label(text, size, color, tx, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, state == "cta")


## Screen title.
func _title(text: String, y: float, size: int = 80, color: Color = CYAN) -> void:
	_label(text, size, color, Vector2(0, y), W, HORIZONTAL_ALIGNMENT_CENTER, true)


func _chip(rect: Rect2, text: String, color: Color = TEXT, coin: bool = false) -> void:
	_panel(rect, PANEL_DARK, BORDER, 3, int(rect.size.y * 0.5))
	var x := rect.position.x + 22.0
	if coin:
		_coin(Vector2(x + 14, rect.position.y + rect.size.y * 0.5), 14.0)
		x += 40.0
	_label(text, 30, color, Vector2(x, rect.position.y + rect.size.y * 0.5 - 22))


func _tier_color(tier: int) -> Color:
	return Tiers.color(tier)


## Square icon with a rank-colored frame.
func _medallion(center: Vector2, size: float, icon_path: String, tier: int) -> void:
	var rect := Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size))
	_panel(rect, PANEL_DARK, _tier_color(tier), 5, int(size * 0.22))
	_tex(icon_path, rect.grow(-size * 0.12))


func _hints(items: Array) -> void:
	# Bottom bar: button glyphs with their action.
	var x := 70.0
	for item in items:
		_ring(Vector2(x + 18, H - 46), 18.0, BORDER, 3.0, 0.0, TAU, item[2])
		_label(item[0], 22, Color("10102a"), Vector2(x + 6, H - 63), 24.0, HORIZONTAL_ALIGNMENT_CENTER)
		_label(item[1], 24, MUTED, Vector2(x + 46, H - 62))
		x += 60.0 + item[1].length() * 14.0 + 40.0


func _stat_bars(pos: Vector2, width: float, values: Array) -> void:
	var names := ["PV", "Dégâts", "Vitesse", "Portée"]
	for k in 4:
		var y := pos.y + k * 46.0
		_label(names[k], 26, MUTED, Vector2(pos.x, y))
		_panel(Rect2(pos.x + 150, y + 6, width - 150, 22), PANEL_DARK, BORDER, 3, 11)
		_panel(Rect2(pos.x + 150, y + 6, (width - 150) * values[k], 22), CYAN, BORDER, 3, 11)


## "Statistiques" panel (shop, pause): stat list in two aligned columns, then families.
func _stats_panel(rect: Rect2) -> void:
	_panel(rect, Color(PANEL, 0.97))
	_label("Statistiques", 36, CYAN, rect.position + Vector2(0, 12), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
	var y := rect.position.y + 66.0
	for row in STATS:
		_label(row[0], 20, TEXT, Vector2(rect.position.x + 22, y))
		var color := TEXT if row[2] == "" else (GOOD if row[2] == "good" else BAD)
		_label(row[1], 20, color, Vector2(rect.position.x, y), rect.size.x - 22, HORIZONTAL_ALIGNMENT_RIGHT)
		y += 28.0
	_label("FAMILLES", 17, MUTED, Vector2(rect.position.x + 22, y + 6))
	var fam := [["Lames", "2/4", Color("ff5f6d"), true], ["Magie", "0/2", CYAN, false], ["Alchimie", "0/2", Color("ff9a3d"), false]]
	y += 32.0
	for f in fam:
		_label(f[0], 21, f[2], Vector2(rect.position.x + 22, y))
		_label(f[1], 21, GOOD if f[3] else TEXT, Vector2(rect.position.x, y), rect.size.x - 22, HORIZONTAL_ALIGNMENT_RIGHT)
		y += 28.0


# --- main menu ---------------------------------------------------------------------

func _logo(pos: Vector2, size: int, width: float, align: int) -> void:
	_label("GATEBOUND", size, CYAN, pos, width, align, true)


## A: the gate. Big portal in the middle, stone pillars and braziers around, the menu in a row.
func _screen_menu_a() -> void:
	_gradient()
	var c := Vector2(960, 560)
	for k in 6:
		_ring(c, 230.0 + k * 95.0, Color(VIOLET, 0.13 - k * 0.02), 12.0)
	_ring(c, 230.0, Color(VIOLET, 0.35), 0.0, 0.0, TAU, Color(0.17, 0.07, 0.35, 0.9))
	_ring(c, 185.0, Color(CYAN, 0.2), 0.0, 0.0, TAU, Color(0.3, 0.12, 0.6, 0.55))
	for k in 5:
		_ring(c, 60.0 + k * 35.0, Color(CYAN, 0.55 - k * 0.08), 7.0, k * 1.3, 4.2)
	_ring(c, 230.0, CYAN, 8.0)
	_ring(c, 242.0, BORDER, 6.0)
	_tex("res://art_source/ai/decor/prop_pillar.png", Rect2(450, 300, 280, 560))
	_tex("res://art_source/ai/decor/prop_pillar.png", Rect2(1190, 300, 280, 560))
	_tex("res://art_source/ai/decor/prop_brazier.png", Rect2(300, 660, 220, 250))
	_tex("res://art_source/ai/decor/prop_brazier.png", Rect2(1400, 660, 220, 250))
	_tex("res://art_source/ai/decor/prop_banner.png", Rect2(640, 290, 120, 240))
	_tex("res://art_source/ai/decor/prop_banner.png", Rect2(1160, 290, 120, 240))
	_logo(Vector2(0, 30), 160, W, HORIZONTAL_ALIGNMENT_CENTER)
	_label("Chasseurs contre portails", 34, MUTED, Vector2(0, 215), W, HORIZONTAL_ALIGNMENT_CENTER)
	var items := ["Jouer", "Coop locale", "Progression", "Paramètres", "Quitter"]
	for i in items.size():
		_button(Rect2(120 + i * 340.0, 880, 320, 84), items[i], "focus" if i == 0 else "normal", 34)
	_label("v0.9.0", 20, MUTED, Vector2(1790, 1030))
	_hints([["A", "Valider", GO], ["B", "Retour", BAD]])


## B: the seal. Menu on the left, a huge rune seal on the right with weapons orbiting it.
func _screen_menu_b() -> void:
	_gradient()
	var c := Vector2(1370, 520)
	for k in 5:
		_ring(c, 300.0 + k * 90.0, Color(VIOLET, 0.13 - k * 0.022), 12.0)
	_ring(c, 330.0, Color(VIOLET, 0.2), 0.0, 0.0, TAU, Color(0.17, 0.07, 0.35, 0.8))
	_tex("res://art_source/ai/decor/decal_rune_circle.png", Rect2(c - Vector2(330, 330), Vector2(660, 660)),
		Rect2(), Color(CYAN, 0.9))
	_ring(c, 330.0, CYAN, 7.0)
	_ring(c, 345.0, BORDER, 6.0)
	var weapons := ["heavy_axe", "longbow", "fire_staff", "rapier", "frost_scepter", "spear", "scythe", "shuriken"]
	for i in weapons.size():
		var a := TAU * i / weapons.size() - PI * 0.5
		var p := c + Vector2.from_angle(a) * 410.0
		_panel(Rect2(p - Vector2(46, 46), Vector2(92, 92)), PANEL_DARK, _tier_color(1 + i % 4), 4, 46)
		_tex(_weapon_icon(weapons[i]), Rect2(p - Vector2(34, 34), Vector2(68, 68)))
	_tex("res://art_source/ai/decor/prop_crystals.png", Rect2(740, 850, 200, 170))
	_tex("res://art_source/ai/decor/prop_crystals.png", Rect2(1760, 850, 150, 130))
	_logo(Vector2(110, 90), 150, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	_label("Chasseurs contre portails", 34, MUTED, Vector2(120, 250))
	var items := ["Jouer", "Coop locale", "Progression", "Paramètres", "Quitter"]
	for i in items.size():
		_button(Rect2(100, 360 + i * 100.0, 520, 80), items[i], "focus" if i == 0 else "normal", 38)
	_label("v0.9.0", 20, MUTED, Vector2(1790, 1030))
	_hints([["A", "Valider", GO], ["B", "Retour", BAD]])


# --- character select --------------------------------------------------------------

func _hero_head(index: int, rect: Rect2, selected: bool, locked: bool = false) -> void:
	_panel(rect, PANEL_DARK, CYAN if selected else BORDER, 6 if selected else BW, 16)
	_tex(_card_path(index), Rect2(rect.position + Vector2(6, 6), rect.size - Vector2(12, 12)),
		Rect2(72, 8, 368, 368), Color(0.18, 0.15, 0.3, 1) if locked else Color.WHITE)
	if locked:
		_label("🔒", 44, TEXT, rect.position + Vector2(0, rect.size.y * 0.5 - 34), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	if selected:
		_panel(rect.grow(7), Color(0, 0, 0, 0), Color(VIOLET, 0.9), 3, 22)


func _select_frame(title: String) -> void:
	_gradient()
	_ring(Vector2(380, 640), 330.0, Color(VIOLET, 0.16), 14.0)
	_ring(Vector2(380, 640), 250.0, Color(CYAN, 0.35), 7.0)
	_panel(Rect2(30, 30, 150, 80), PANEL, BORDER, BW, 40)
	_label("◀", 46, TEXT, Vector2(30, 38), 150, HORIZONTAL_ALIGNMENT_CENTER)
	_label(title, 64, CYAN, Vector2(220, 36), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)


func _hero_panel(index: int) -> void:
	# Full hero on the left (above the info plate), the sex switch at the top-right of its area.
	_tex(_card_path(index), Rect2(40, 118, 700, 520))
	_label("♂", 56, Color("5fb4ff"), Vector2(660, 118))
	_panel(Rect2(40, 650, 700, 350), Color(PANEL_DARK, 0.92))
	_label(HEROES[index][1].to_upper(), 56, CYAN, Vector2(70, 656), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(HEROES[index][2], 22, TEXT, Vector2(70, 724), 640)
	_stat_bars(Vector2(70, 810), 640, [0.55, 0.7, 0.62, 0.78])


func _screen_select() -> void:
	_select_frame("CHOISIS TON CHASSEUR")
	_hero_panel(0)
	# Bonus / malus of the class, as colored chips.
	_label("Bonus et malus", 28, MUTED, Vector2(790, 130))
	var chips: Array = HEROES[0][4]
	for i in chips.size():
		var bad: bool = String(chips[i]).begins_with("-")
		_chip(Rect2(790 + (i % 2) * 330.0, 170 + (i / 2) * 64.0, 310, 52), chips[i], BAD if bad else GOOD)
	# Heads of the seven classes (the switch on the hero panel gives the other look).
	_label("Chasseurs", 28, MUTED, Vector2(790, 330))
	for n in 7:
		var rect := Rect2(790 + (n % 4) * 190.0, 370 + (n / 4) * 190.0, 170, 170)
		_hero_head(n, rect, n == 0, n == 5)
	# Starting weapons: the next step of the flow, shown already.
	_label("Arme de départ", 28, MUTED, Vector2(790, 790))
	_button(Rect2(790, 830, 330, 84), "Arc long", "focus", 30)
	_tex(_weapon_icon("longbow"), Rect2(1040, 836, 72, 72))
	_button(Rect2(1140, 830, 330, 84), "Arbalète", "normal", 26)
	_tex(_weapon_icon("smg"), Rect2(1390, 836, 72, 72))
	_button(Rect2(1560, 800, 320, 150), "JOUER", "cta", 56)
	_hints([["A", "Choisir", GO], ["B", "Retour", BAD], ["Y", "♀ / ♂", GOLD]])


func _screen_select_seals() -> void:
	_select_frame("CHOISIS TON SCEAU")
	_hero_panel(0)
	var romans := ["I", "II", "III", "IV", "V", "VI"]
	var names := ["Cuivre", "Fer", "Argent", "Or", "Obsidienne", "Astral"]
	var heat := [Color("4de0b8"), Color("a6e34d"), Color("ffd84d"), Color("ff9a3d"), Color("ff4a3d"), Color("c8102e")]
	for i in 6:
		var rect := Rect2(790 + (i % 3) * 360.0, 150 + (i / 3) * 290.0, 340, 270)
		var locked := i > 3
		_panel(rect, Color(PANEL, 0.97), Color(heat[i], 0.9) if not locked else BORDER, 6 if i == 1 else BW, 20)
		_label(romans[i], 96, heat[i] if not locked else Color(MUTED, 0.5), rect.position + Vector2(0, 6), 340,
			HORIZONTAL_ALIGNMENT_CENTER, true)
		_label("☠".repeat(i) if not locked else "🔒", 30, heat[i] if not locked else MUTED,
			rect.position + Vector2(0, 126), 340, HORIZONTAL_ALIGNMENT_CENTER)
		_label(names[i], 28, TEXT if not locked else MUTED, rect.position + Vector2(0, 168), 340, HORIZONTAL_ALIGNMENT_CENTER)
		# Rewards: silhouettes until the seal is won.
		var rewards := ["heavy_axe", "lucky_coin", "magnet_glove"]
		for r in 3:
			var sil := Color(0.32, 0.27, 0.45, 0.9)
			_tex(_weapon_icon(rewards[r]) if r == 0 else _item_icon(rewards[r]),
				Rect2(rect.position + Vector2(90 + r * 56.0, 208), Vector2(48, 48)), Rect2(), sil if i > 0 else Color.WHITE)
	_panel(Rect2(790, 740, 1090, 120), Color(PANEL_DARK, 0.92))
	_label("Fer · Temple englouti", 34, heat[1], Vector2(820, 748))
	_label("Élites +1 % · PV et dégâts +12 % · Boss : Gardien de pierre puis Idole colossale", 24, MUTED,
		Vector2(820, 800), 1030)
	_button(Rect2(1560, 900, 320, 110), "ENTRER", "cta", 50)
	_hints([["A", "Choisir", GO], ["B", "Retour", BAD]])


# --- shop ---------------------------------------------------------------------------

func _offer_card(rect: Rect2, tier: int, tag: String, name_text: String, desc: String, icon: String,
		price: int, state: String = "") -> void:
	var accent := _tier_color(tier)
	if state == "sold":
		_panel(rect, Color(PANEL, 0.4), Color(accent, 0.3), BW, 20)
		_label("VENDU", 40, Color(accent, 0.6), rect.position + Vector2(0, rect.size.y * 0.5 - 30), rect.size.x,
			HORIZONTAL_ALIGNMENT_CENTER, true)
		return
	_panel(rect, PANEL, accent, 5, 20)
	_medallion(rect.position + Vector2(rect.size.x * 0.5, 110), 116.0, icon, tier)
	_label(tag, 18, accent, rect.position + Vector2(0, 182), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_label(name_text, 31, TEXT, rect.position + Vector2(10, 208), rect.size.x - 20, HORIZONTAL_ALIGNMENT_CENTER)
	_label(desc, 21, MUTED, rect.position + Vector2(20, 262), rect.size.x - 40, HORIZONTAL_ALIGNMENT_CENTER)
	if state == "merge":
		_label("★ FUSION POSSIBLE", 18, GOLD, rect.position + Vector2(0, 322), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_button(Rect2(rect.position + Vector2(20, rect.size.y - 128), Vector2(rect.size.x - 40, 64)),
		"Acheter", "focus" if state == "focus" else "normal", 28, price)
	_button(Rect2(rect.position + Vector2(60, rect.size.y - 56), Vector2(rect.size.x - 120, 40)),
		"🔒 Verrouiller", "normal", 20)


func _screen_shop() -> void:
	_arena_dim()
	_label("BOUTIQUE", 76, CYAN, Vector2(70, 22), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_chip(Rect2(480, 38, 190, 56), "Vague 1", TEXT)
	_chip(Rect2(700, 38, 230, 56), "30", GOLD, true)
	var x := 70.0
	var cards := [
		[1, "ARME · I · LAMES", "Hache de guerre", "Coup lent mais très large qui repousse les ennemis.", "heavy_axe", 24, "focus"],
		[1, "OBJET · I", "Trèfle doré", "+15 Chance", "lucky_coin", 18, ""],
		[1, "ARME · I · ALCHIMIE", "Grenades à fragments", "Trois grenades lancées en éventail, petites explosions.", "frag_grenade", 22, "sold"],
		[1, "OBJET · I", "Gant de magnétite", "+40 Portée de ramassage", "magnet_glove", 10, ""],
	]
	for i in 4:
		var c: Array = cards[i]
		var icon: String = _weapon_icon(c[4]) if String(c[1]).begins_with("ARME") else _item_icon(c[4])
		_offer_card(Rect2(x + i * 320.0, 130, 300, 470), c[0], c[1], c[2], c[3], icon, c[5], c[6])
	_button(Rect2(540, 625, 280, 64), "Relancer", "normal", 28, 1)
	# Owned weapons: the two identical ones are mergeable (gold frame), one selected.
	_label("ARMES", 26, MUTED, Vector2(70, 712))
	_label("2 / 6", 26, MUTED, Vector2(190, 712))
	for i in 2:
		var rect := Rect2(70 + i * 330.0, 750, 310, 76)
		_panel(rect, PANEL_DARK, GOLD, 5, 20)
		_tex(_weapon_icon("katana"), Rect2(rect.position + Vector2(8, 8), Vector2(60, 60)))
		_label("Épée flamboyante I", 22, _tier_color(1), rect.position + Vector2(78, 22))
	_button(Rect2(70, 842, 220, 56), "Vendre", "normal", 24, 6)
	_button(Rect2(310, 842, 220, 56), "Fusionner", "focus", 24)
	# Owned items with their count.
	_label("OBJETS", 26, MUTED, Vector2(70, 928))
	var items := [["oni_mask", 2, 1], ["magnet_glove", 3, 2], ["plasma_ring", 1, 3]]
	for i in items.size():
		var rect := Rect2(190 + i * 72.0, 914, 62, 62)
		_panel(rect, PANEL_DARK, _tier_color(items[i][2]), 4, 14)
		_tex(_item_icon(items[i][0]), rect.grow(-7))
		if items[i][1] > 1:
			_label("×%d" % items[i][1], 18, TEXT, rect.position + Vector2(24, 40))
	_button(Rect2(1090, 930, 440, 100), "Vague suivante  ▶", "cta", 46)
	_stats_panel(Rect2(1540, 90, 360, 880))
	_hints([["A", "Acheter", GO], ["X", "Verrouiller", Color("5fb4ff")], ["Y", "Relancer", GOLD]])


# --- pause --------------------------------------------------------------------------

func _screen_pause() -> void:
	_arena_dim()
	_panel(Rect2(480, 200, 560, 700), Color(PANEL, 0.97), CYAN, 5, 26)
	_label("PAUSE", 100, CYAN, Vector2(480, 220), 560, HORIZONTAL_ALIGNMENT_CENTER, true)
	_chip(Rect2(570, 350, 380, 50), "Vague 1 / 20  ·  00:17", MUTED)
	var items := ["Reprendre", "Paramètres", "Recommencer", "Menu principal", "Quitter"]
	for i in items.size():
		_button(Rect2(530, 430 + i * 82.0, 460, 68), items[i], "focus" if i == 0 else "normal", 32)
	_stats_panel(Rect2(1090, 90, 360, 880))
	_hints([["A", "Valider", GO], ["B", "Reprendre", BAD]])


# --- settings -----------------------------------------------------------------------

func _slider(pos: Vector2, width: float, value: float, text: String, focus: bool = false) -> void:
	_panel(Rect2(pos + Vector2(0, 10), Vector2(width, 20)), PANEL_DARK, BORDER, 3, 10)
	_panel(Rect2(pos + Vector2(0, 10), Vector2(width * value, 20)), CYAN, BORDER, 3, 10)
	_ring(pos + Vector2(width * value, 20), 17.0, CYAN if focus else BORDER, 4.0, 0.0, TAU, TEXT)
	_label(text, 28, TEXT, pos + Vector2(width + 30, -4))


func _toggle(pos: Vector2, on: bool) -> void:
	_panel(Rect2(pos, Vector2(86, 42)), Color("2f8f55") if on else PANEL_DARK, BORDER, 4, 21)
	_ring(pos + Vector2(65 if on else 21, 21), 15.0, BORDER, 3.0, 0.0, TAU, TEXT)


func _screen_settings() -> void:
	_arena_dim()
	_panel(Rect2(360, 60, 1200, 960), Color(PANEL, 0.97), CYAN, 5, 26)
	_label("PARAMÈTRES", 84, CYAN, Vector2(360, 72), 1200, HORIZONTAL_ALIGNMENT_CENTER, true)
	var y := 180.0
	var sections := [
		["AUDIO", [["Volume général", 1.0, "100 %"], ["Musique", 0.25, "25 %"], ["Effets sonores", 1.0, "100 %"]]],
		["AFFICHAGE", [["Plein écran", true], ["Synchronisation verticale", true]]],
		["JEU", [["Tremblement de l'écran", true], ["Chiffres de dégâts", true], ["Réduire les animations des menus", false],
			["Afficher les astuces", true]]],
	]
	var row_index := 0
	for section in sections:
		_label(section[0], 24, VIOLET, Vector2(420, y))
		_panel(Rect2(420 + 150, y + 16, 1080 - 150 - 60, 3), Color(VIOLET, 0.4), Color(0, 0, 0, 0), 0, 2)
		y += 44.0
		for row in section[1]:
			var focus := row_index == 1
			if focus:
				_panel(Rect2(405, y - 8, 1110, 58), Color(CYAN, 0.12), CYAN, 3, 16)
			_label(row[0], 30, TEXT, Vector2(430, y))
			if row.size() == 3:
				_slider(Vector2(920, y + 6), 380.0, row[1], row[2], focus)
			else:
				_toggle(Vector2(1400, y + 2), row[1])
			y += 54.0
			row_index += 1
		y += 8.0
	_label("Langue", 30, TEXT, Vector2(430, y))
	_panel(Rect2(1100, y - 6, 380, 56), PANEL_DARK, BORDER, 4, 28)
	_label("Français", 28, TEXT, Vector2(1100, y + 2), 300, HORIZONTAL_ALIGNMENT_CENTER)
	_label("▾", 28, MUTED, Vector2(1440, y + 2))
	_button(Rect2(760, 920, 400, 76), "Retour", "focus", 36)
	_hints([["A", "Modifier", GO], ["B", "Retour", BAD]])


# --- level-up -----------------------------------------------------------------------

func _screen_levelup() -> void:
	_arena_dim()
	_title("NIVEAU SUPÉRIEUR !", 90, 110)
	_label("Choisis une amélioration", 36, MUTED, Vector2(0, 230), W, HORIZONTAL_ALIGNMENT_CENTER)
	var cards := [
		["Soif de sang", "+3 % Vol de vie", "Vol de vie : 0 % → 3 %", "blood_chalice", 1],
		["Frénésie", "+8 % Vitesse d'attaque", "Vitesse d'attaque : +0 % → +7 %", "swift_rune", 2],
		["Puissance", "+8 % Dégâts", "Dégâts : -10 % → -3 %", "sharpened_edge", 1],
		["Précision", "+5 % Chance de critique", "Chance de critique : 0 % → 5 %", "focus_lens", 3],
	]
	for i in 4:
		var c: Array = cards[i]
		var rect := Rect2(210 + i * 360.0, 310, 330, 470)
		var accent := _tier_color(c[4])
		_panel(rect, PANEL, accent, 6 if i == 0 else 5, 22)
		_medallion(rect.position + Vector2(rect.size.x * 0.5, 130), 130.0, _item_icon(c[3]), c[4])
		_label("AMÉLIORATION · %s" % ["I", "II", "III", "IV"][c[4] - 1], 19, accent,
			rect.position + Vector2(0, 218), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_label(c[0], 40, TEXT, rect.position + Vector2(0, 250), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
		_label(c[1], 26, TEXT, rect.position + Vector2(10, 320), rect.size.x - 20, HORIZONTAL_ALIGNMENT_CENTER)
		_label(c[2], 19, GOOD, rect.position + Vector2(10, 390), rect.size.x - 20, HORIZONTAL_ALIGNMENT_CENTER)
		if i == 0:
			_panel(rect.grow(8), Color(0, 0, 0, 0), CYAN, 3, 28)
	_button(Rect2(760, 830, 400, 72), "Relancer", "normal", 30, 1)
	_hints([["A", "Choisir", GO], ["Y", "Relancer", GOLD]])


# --- main menu, new proposals (C1-C3): living portal, monsters coming out of it -------

## A monster frame standing with its feet at `feet`, `height` px tall (`flip`: facing left).
func _mob(id: String, feet: Vector2, height: float, flip: bool = false, tint: Color = Color.WHITE) -> void:
	var w := height * 1.02
	var r := _tex("res://assets_src/ai/ai_%s/idle_0.png" % id, Rect2(feet - Vector2(w * 0.5, height * 0.96), Vector2(w, height)),
		Rect2(), tint)
	r.clip_contents = false
	if flip:
		r.pivot_offset = r.size * 0.5
		r.scale = Vector2(-1, 1)


func _line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	var l := Line2D.new()
	l.points = PackedVector2Array([a, b])
	l.width = width
	l.default_color = color
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	_root.add_child(l)


## Arena floor, lit (the menu is not dimmed): stone tiles as in the arena.
func _floor(bright: float = 1.0) -> void:
	var base := ColorRect.new()
	base.color = Color("2a2150").darkened(1.0 - bright)
	base.size = Vector2(W, H)
	_root.add_child(base)
	for row in 14:
		for col in 15:
			var off := 70.0 if row % 2 == 1 else 0.0
			var shade := 0.03 * float((row * 7 + col * 3) % 4)
			var p := Panel.new()
			p.position = Vector2(col * 140.0 - off, row * 80.0)
			p.size = Vector2(136, 76)
			p.add_theme_stylebox_override("panel", _style(Color(0.2 + shade, 0.17 + shade, 0.36 + shade, 0.85).darkened(1.0 - bright),
				Color(0.1, 0.08, 0.2, 0.9), 2, 6))
			_root.add_child(p)


## Dark fade on the left so the menu stays readable over the scene.
func _left_fade(width: float = 900.0, alpha: float = 0.92) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(BG_A, alpha))
	g.set_color(1, Color(BG_A, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 8
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	var r := TextureRect.new()
	r.texture = gt
	r.size = Vector2(width, H)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	_root.add_child(r)


## Living portal: soft glow rings, a swirling core with spiral arms, a bright rim.
func _portal(c: Vector2, radius: float, rim: Color = CYAN, core: Color = Color("3a1578")) -> void:
	for k in 4:
		_ring(c, radius + 30.0 + k * 40.0, Color(rim, 0.14 - k * 0.03), 18.0)
	_ring(c, radius, Color(0, 0, 0, 0), 0.0, 0.0, TAU, core)
	_ring(c, radius * 0.8, Color(0, 0, 0, 0), 0.0, 0.0, TAU, core.lightened(0.18))
	_ring(c, radius * 0.55, Color(0, 0, 0, 0), 0.0, 0.0, TAU, core.lightened(0.38))
	_ring(c, radius * 0.28, Color(0, 0, 0, 0), 0.0, 0.0, TAU, Color(0.85, 0.7, 1.0, 0.9))
	for k in 6:
		_ring(c, radius * (0.2 + 0.14 * k), Color(rim, 0.75 - k * 0.09), 8.0 - k * 0.6, k * 1.05, 3.6)
	_ring(c, radius, rim, 10.0)
	_ring(c, radius + 12.0, BORDER, 8.0)


func _menu_left() -> void:
	_logo(Vector2(110, 90), 150, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	_label("Chasseurs contre portails", 34, MUTED, Vector2(120, 250))
	var items := ["Jouer", "Coop locale", "Progression", "Paramètres", "Quitter"]
	for i in items.size():
		_button(Rect2(100, 360 + i * 100.0, 520, 80), items[i], "focus" if i == 0 else "normal", 38)
	_label("v0.9.0", 20, MUTED, Vector2(1790, 1030))
	_hints([["A", "Valider", GO], ["B", "Retour", BAD]])


func _floor_props() -> void:
	_tex("res://art_source/ai/decor/decal_rune_circle.png", Rect2(1000, 640, 360, 360), Rect2(), Color(VIOLET, 0.55))
	_tex("res://art_source/ai/decor/decal_rune_circle.png", Rect2(1560, 130, 260, 260), Rect2(), Color(VIOLET, 0.4))
	_tex("res://art_source/ai/decor/decal_cracks.png", Rect2(760, 470, 260, 200), Rect2(), Color(1, 1, 1, 0.5))
	_tex("res://art_source/ai/decor/decal_bones.png", Rect2(1460, 760, 200, 160), Rect2(), Color(1, 1, 1, 0.7))
	_tex("res://art_source/ai/decor/decal_bones.png", Rect2(820, 900, 180, 140), Rect2(), Color(1, 1, 1, 0.7))


## C1 "Invasion": the monsters pour out of the portal and spread over the arena.
func _screen_menu_c1() -> void:
	_floor(0.75)
	_floor_props()
	_portal(Vector2(1440, 330), 250.0)
	_tex("res://art_source/ai/decor/prop_pillar.png", Rect2(1090, 120, 220, 440))
	_tex("res://art_source/ai/decor/prop_pillar.png", Rect2(1600, 120, 220, 440))
	_tex("res://art_source/ai/decor/prop_brazier.png", Rect2(1000, 480, 150, 170))
	_tex("res://art_source/ai/decor/prop_brazier.png", Rect2(1700, 480, 150, 170))
	# Far to near: small near the portal, big at the bottom (perspective).
	var crowd := [
		["grunt", 1330, 520, 110, false], ["runner", 1460, 540, 100, false], ["kamikaze", 1560, 530, 100, false],
		["tank", 1250, 640, 170, true], ["shooter", 1500, 660, 140, false], ["charger", 1660, 650, 150, true],
		["grunt", 1130, 760, 190, true], ["runner", 1380, 790, 170, false], ["tank", 1600, 800, 230, true],
		["spawner", 1800, 780, 200, true], ["charger", 960, 900, 230, false], ["grunt", 1250, 930, 260, true],
		["shooter", 1500, 960, 250, false], ["runner", 1740, 980, 260, true],
	]
	for m in crowd:
		_mob(m[0], Vector2(m[1], m[2]), m[3], m[4])
	_left_fade(880)
	_menu_left()


## C2 "Le seigneur du portail": a demon knight steps out of a red portal, his horde behind him.
func _screen_menu_c2() -> void:
	_floor(0.7)
	_floor_props()
	var red := Color("ff5577")
	_portal(Vector2(1400, 380), 330.0, red, Color("4a1030"))
	_mob("grunt", Vector2(1030, 700), 150, false)
	_mob("runner", Vector2(1130, 640), 120, false)
	_mob("kamikaze", Vector2(1730, 650), 130, true)
	_mob("charger", Vector2(1830, 720), 180, true)
	_mob("shooter", Vector2(1010, 850), 200, false)
	_mob("tank", Vector2(1840, 900), 260, true)
	_mob("shogun", Vector2(1420, 1010), 800, true)
	_mob("runner", Vector2(1130, 990), 190, false)
	_mob("grunt", Vector2(1680, 1040), 230, true)
	_left_fade(880)
	_menu_left()


## C3 "La ruée": a diagonal rush with speed lines, the portal cropped in the top-right corner.
func _screen_menu_c3() -> void:
	_floor(0.8)
	_floor_props()
	_portal(Vector2(1720, 120), 430.0)
	for k in 26:
		var y := 80.0 + k * 40.0
		var x := 800.0 + float((k * 137) % 900)
		_line(Vector2(x + 260.0, y - 90.0), Vector2(x, y + 25.0), Color(CYAN, 0.12 + 0.1 * float(k % 3)), 3.0 + k % 4)
	var rush := [
		["kamikaze", 1500, 470, 120, false], ["runner", 1290, 560, 150, false], ["grunt", 1640, 600, 190, false],
		["shooter", 1110, 690, 190, false], ["charger", 1490, 760, 260, false], ["tank", 940, 830, 290, false],
		["grunt", 1280, 920, 300, false], ["runner", 1700, 940, 280, false], ["spawner", 1810, 760, 220, false],
	]
	for m in rush:
		_mob(m[0], Vector2(m[1], m[2]), m[3], m[4])
	_left_fade(900)
	_menu_left()
