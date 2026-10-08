extends Node
## Debug tool: draws UI mockups of the "Portal" theme proposal with the real game
## data and art (offers, icons, stats, settings), and saves a screenshot.
## Nothing here is used by the game: it is a throwaway proposal to validate.
## Usage: Godot.exe --path . res://src/debug/ui_mockup.tscn -- --screen=<name> --out=<png>
## Screens: menu_a, menu_b, menu_c1, menu_c2, menu_c3, select, select_seals, shop, pause, settings, levelup,
## select_v2_a, select_v2_b, select_v2_c, select_v3, select_v3_coop, select_v4, select_v4_coop, select_v5_dalles,
## select_v6, select_v7_solo, select_v7_coop_a, select_v7_coop_b, danger_a, danger_b, danger_c, danger_coop

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


# --- character select v2 (proposals, 2026-10-08) ------------------------------------

const V2_WEAPONS := [["longbow", "Arc long", "Flèches perçantes à longue portée."],
	["smg", "Arbalète à répétition", "Rafales de carreaux rapides."]]
const SEAL_HEAT := [Color("4de0b8"), Color("a6e34d"), Color("ffd84d"), Color("ff9a3d"), Color("ff4a3d"), Color("c8102e")]


## Shared backdrop of the v2 proposals: night gradient, faint rune seal behind the
## hero (the dungeon portal of the main menu), a soft floor glow.
func _v2_backdrop(hero_center: Vector2) -> void:
	_gradient()
	_tex("res://art_source/ai/decor/decal_rune_circle.png", Rect2(hero_center - Vector2(420, 420), Vector2(840, 840)),
		Rect2(), Color(VIOLET, 0.22))
	for k in 3:
		_ring(hero_center, 300.0 + k * 70.0, Color(CYAN, 0.10 - k * 0.03), 6.0)
	_ring(hero_center + Vector2(0, 330), 260.0, Color(0, 0, 0, 0), 0.0, 0.0, TAU, Color(VIOLET, 0.18))


func _v2_seal(rect: Rect2, level: int, state: String) -> void:
	var locked := state == "locked"
	var heat: Color = SEAL_HEAT[level]
	_panel(rect, Color(PANEL, 0.95), Color.WHITE if state == "selected" else (BORDER if locked else Color(heat, 0.7)),
		6 if state == "selected" else BW, 16)
	_label(["I", "II", "III", "IV", "V", "VI"][level], int(rect.size.y * 0.42), heat if not locked else Color(MUTED, 0.5),
		rect.position + Vector2(0, 2), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
	_label("☠".repeat(level) if not locked else "🔒", int(rect.size.y * 0.18), heat if not locked else MUTED,
		rect.position + Vector2(0, rect.size.y * 0.58), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _v2_weapon_card(rect: Rect2, weapon: Array, focused: bool) -> void:
	_panel(rect, Color(PANEL, 0.95), CYAN if focused else BORDER, 5 if focused else BW, 18)
	_tex(_weapon_icon(weapon[0]), Rect2(rect.position + Vector2(16, 14), Vector2(rect.size.y - 28, rect.size.y - 28)))
	_label(weapon[1], 28, Tiers.color(1), rect.position + Vector2(rect.size.y, 16), rect.size.x - rect.size.y - 16)
	_label(weapon[2], 20, MUTED, rect.position + Vector2(rect.size.y, 56), rect.size.x - rect.size.y - 16)


func _v2_back() -> void:
	_panel(Rect2(40, 30, 170, 64), PANEL, BORDER, BW, 32)
	_label("Retour", 28, TEXT, Vector2(40, 42), 170, HORIZONTAL_ALIGNMENT_CENTER)


## A: same layout as today, but nothing is empty on arrival: the last hero played is
## already selected (art, stats, weapons, seal, Play), the focus is on his head.
func _screen_select_v2_a() -> void:
	_v2_backdrop(Vector2(390, 420))
	_v2_back()
	_label("CHOISIS TON CHASSEUR", 64, CYAN, Vector2(240, 26), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_tex(_card_path(0), Rect2(60, 110, 660, 520))
	_label("♂", 52, Color("5fb4ff"), Vector2(650, 110))
	_panel(Rect2(40, 640, 700, 330), Color(PANEL_DARK, 0.92))
	_label(HEROES[0][1].to_upper(), 54, Color("ff6b6b"), Vector2(70, 650), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(HEROES[0][2], 22, TEXT, Vector2(70, 716), 640)
	_stat_bars(Vector2(70, 790), 640, [0.55, 0.7, 0.62, 0.78])
	for n in 7:
		_hero_head(n, Rect2(790 + n * 158.0, 110, 146, 146), n == 0, n == 5)
	_label("Arme de départ", 28, MUTED, Vector2(790, 290))
	_v2_weapon_card(Rect2(790, 330, 520, 110), V2_WEAPONS[0], false)
	_v2_weapon_card(Rect2(1330, 330, 520, 110), V2_WEAPONS[1], false)
	_label("Sceau", 28, MUTED, Vector2(790, 480))
	for i in 6:
		_v2_seal(Rect2(790 + i * 180.0, 520, 166, 120), i, "selected" if i == 1 else ("locked" if i > 2 else ""))
	_label("Fer · Temple englouti", 30, SEAL_HEAT[1], Vector2(790, 660))
	_label("Élites 1 % · Ennemis +12 % PV et dégâts", 22, MUTED, Vector2(790, 704))
	_button(Rect2(1500, 860, 360, 110), "JOUER", "cta", 52)
	_label("Dernier chasseur joué présélectionné : tout est prêt, A sur JOUER pour relancer.", 20, MUTED,
		Vector2(790, 900), 680)
	_hints([["A", "Choisir", GO], ["B", "Retour", BAD], ["Y", "♀ / ♂", GOLD]])


## B: showcase. The hero stands big in the middle on the portal (breathing), the
## seven heads are a carousel at the bottom; info on the left, loadout on the right.
func _screen_select_v2_b() -> void:
	_v2_backdrop(Vector2(960, 470))
	_label("CHOISIS TON CHASSEUR", 60, CYAN, Vector2(0, 22), W, HORIZONTAL_ALIGNMENT_CENTER, true)
	_v2_back()
	_tex(_card_path(0), Rect2(660, 100, 600, 640))
	_label("♂", 52, Color("5fb4ff"), Vector2(1220, 120))
	_panel(Rect2(40, 130, 560, 600), Color(PANEL_DARK, 0.85))
	_label(HEROES[0][1].to_upper(), 64, Color("ff6b6b"), Vector2(70, 140), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(HEROES[0][2], 24, TEXT, Vector2(70, 220), 500)
	var chips: Array = HEROES[0][4]
	for i in chips.size():
		var bad: bool = String(chips[i]).begins_with("-")
		_label(("▼ " if bad else "▲ ") + chips[i], 24, BAD if bad else GOOD, Vector2(70 + (i % 2) * 250.0, 320 + (i / 2) * 40.0))
	_stat_bars(Vector2(70, 440), 500, [0.55, 0.7, 0.62, 0.78])
	_panel(Rect2(1320, 130, 560, 600), Color(PANEL_DARK, 0.85))
	_label("Arme de départ", 28, MUTED, Vector2(1350, 145))
	_v2_weapon_card(Rect2(1350, 190, 500, 110), V2_WEAPONS[0], true)
	_v2_weapon_card(Rect2(1350, 314, 500, 110), V2_WEAPONS[1], false)
	_label("Sceau", 28, MUTED, Vector2(1350, 450))
	for i in 6:
		_v2_seal(Rect2(1350 + (i % 3) * 168.0, 490 + (i / 3) * 112.0, 156, 100), i,
			"selected" if i == 1 else ("locked" if i > 2 else ""))
	var x := 300.0
	for n in 7:
		var big := n == 0
		var s := 150.0 if big else 120.0
		_hero_head(n, Rect2(x, 800 + (0.0 if big else 15.0), s, s), big, n == 5)
		x += s + 18.0
	_button(Rect2(1540, 820, 340, 120), "JOUER", "cta", 54)
	_hints([["LB/RB", "Chasseur", MUTED], ["A", "Choisir", GO], ["B", "Retour", BAD], ["Y", "♀ / ♂", GOLD]])


## C: three steps side by side. 1 hunter list (names), 2 preview, 3 loadout and Play;
## the step being edited is lit, the others stay readable.
func _screen_select_v2_c() -> void:
	_v2_backdrop(Vector2(860, 470))
	_v2_back()
	var steps := [["1", "CHASSEUR", Rect2(40, 120, 420, 860)], ["2", "APERÇU", Rect2(490, 120, 760, 860)],
		["3", "ÉQUIPEMENT", Rect2(1280, 120, 600, 860)]]
	for k in 3:
		var r: Rect2 = steps[k][2]
		_panel(r, Color(PANEL_DARK, 0.8), CYAN if k == 0 else BORDER, 5 if k == 0 else BW, 22)
		_label(steps[k][0] + "  " + steps[k][1], 34, CYAN if k == 0 else MUTED, r.position + Vector2(24, 14), 0.0,
			HORIZONTAL_ALIGNMENT_LEFT, true)
	for n in 7:
		var row := Rect2(60, 180 + n * 110.0, 380, 96)
		_panel(row, Color("4a2a86") if n == 0 else Color(PANEL, 0.9), CYAN if n == 0 else BORDER, 4, 16)
		_tex(_card_path(n), Rect2(row.position + Vector2(8, 8), Vector2(80, 80)), Rect2(72, 8, 368, 368),
			Color(0.18, 0.15, 0.3, 1) if n == 5 else Color.WHITE)
		_label(HEROES[n][1] if n != 5 else "🔒 ???", 28, TEXT if n != 5 else MUTED, row.position + Vector2(104, 26))
	_tex(_card_path(0), Rect2(540, 180, 660, 480))
	_label(HEROES[0][1].to_upper(), 56, Color("ff6b6b"), Vector2(520, 670), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(HEROES[0][2], 22, TEXT, Vector2(520, 736), 700)
	_stat_bars(Vector2(520, 800), 700, [0.55, 0.7, 0.62, 0.78])
	_v2_weapon_card(Rect2(1300, 190, 560, 104), V2_WEAPONS[0], false)
	_v2_weapon_card(Rect2(1300, 306, 560, 104), V2_WEAPONS[1], false)
	for i in 6:
		_v2_seal(Rect2(1300 + (i % 3) * 188.0, 440 + (i / 3) * 118.0, 176, 104), i,
			"selected" if i == 1 else ("locked" if i > 2 else ""))
	_label("Fer · Temple englouti", 28, SEAL_HEAT[1], Vector2(1300, 690))
	_button(Rect2(1340, 840, 480, 110), "JOUER", "cta", 52)
	_hints([["A", "Valider", GO], ["B", "Étape précédente", BAD], ["Y", "♀ / ♂", GOLD]])


# --- character select v3: the dev picked C (2026-10-08) -----------------------------

## Hunter list row: head and class name.
func _v3_row(rect: Rect2, index: int, focused: bool, locked: bool = false) -> void:
	_panel(rect, Color("4a2a86") if focused else Color(PANEL, 0.9), CYAN if focused else BORDER, 4, 16)
	var head := rect.size.y - 16.0
	_tex(_card_path(index), Rect2(rect.position + Vector2(8, 8), Vector2(head, head)), Rect2(72, 8, 368, 368),
		Color(0.18, 0.15, 0.3, 1) if locked else Color.WHITE)
	_label(HEROES[index][1] if not locked else "🔒 ???", int(rect.size.y * 0.3), TEXT if not locked else MUTED,
		rect.position + Vector2(head + 24, rect.size.y * 0.5 - rect.size.y * 0.21))


## Look switch of the middle panel: ◀ ♀ ♂ ▶, the current look lit.
func _v3_looks(center: Vector2, focused: bool, male: bool) -> void:
	var rect := Rect2(center - Vector2(170, 34), Vector2(340, 68))
	_panel(rect, Color("4a2a86") if focused else Color(PANEL, 0.9), CYAN if focused else BORDER, 4, 34)
	_label("◀", 30, CYAN if focused else MUTED, rect.position + Vector2(20, 12))
	_label("▶", 30, CYAN if focused else MUTED, rect.position + Vector2(rect.size.x - 50, 12))
	_label("♀", 40, Color("ff7ab8") if not male else Color(MUTED, 0.5), rect.position + Vector2(110, 6))
	_label("♂", 40, Color("5fb4ff") if male else Color(MUTED, 0.5), rect.position + Vector2(190, 6))


## One column panel; `lit` = the step being edited.
func _v3_column(rect: Rect2, title: String, lit: bool) -> void:
	_panel(rect, Color(PANEL_DARK, 0.8), CYAN if lit else BORDER, 5 if lit else BW, 22)
	if title != "":
		_label(title, 34, CYAN if lit else MUTED, rect.position + Vector2(24, 14), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)


## Solo: list, look, weapon. The step shown here: the look (middle column lit).
func _screen_select_v3() -> void:
	_v2_backdrop(Vector2(860, 470))
	_v2_back()
	_label("CHOISIS TON PERSONNAGE", 56, CYAN, Vector2(240, 30), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_v3_column(Rect2(40, 120, 420, 860), "PERSONNAGE", false)
	_v3_column(Rect2(490, 120, 760, 860), "", true)
	_v3_column(Rect2(1280, 120, 600, 860), "ARME", false)
	for n in 7:
		_v3_row(Rect2(60, 180 + n * 110.0, 380, 96), n, n == 0, n == 5)
	_tex(_card_path(0), Rect2(540, 140, 660, 500))
	_v3_looks(Vector2(870, 680), true, false)
	_label(HEROES[0][1].to_upper(), 52, Color("ff6b6b"), Vector2(520, 720), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(HEROES[0][2], 22, TEXT, Vector2(520, 780), 700)
	_stat_bars(Vector2(520, 830), 700, [0.55, 0.7, 0.62, 0.78])
	_v2_weapon_card(Rect2(1300, 190, 560, 104), V2_WEAPONS[0], false)
	_v2_weapon_card(Rect2(1300, 306, 560, 104), V2_WEAPONS[1], false)
	_label("Sceau", 26, MUTED, Vector2(1300, 428))
	for i in 6:
		_v2_seal(Rect2(1300 + (i % 3) * 188.0, 466 + (i / 3) * 118.0, 176, 104), i,
			"selected" if i == 1 else ("locked" if i > 2 else ""))
	_label("Fer · Temple englouti", 28, SEAL_HEAT[1], Vector2(1300, 712))
	_button(Rect2(1340, 840, 480, 110), "JOUER", "cta", 52)
	_hints([["A", "Valider", GO], ["B", "Retour", BAD], ["◀ ▶", "Apparence", GOLD]])


## Coop: one half per player, the same three steps in two columns (the list stays,
## the right column shows the look, then the weapon under it). Player 1 also picks
## the seal and Play; the run starts when both are ready.
func _screen_select_v3_coop() -> void:
	_gradient()
	for p in 2:
		var x0 := 960.0 * p
		var color: Color = RunPlayer.COLORS[p]
		_ring(Vector2(x0 + 640, 420), 300.0, Color(VIOLET, 0.12), 10.0)
		_label("JOUEUR %d" % (p + 1), 44, color, Vector2(x0 + 30, 22), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
		_label("Manette %d" % (p + 1), 20, MUTED, Vector2(x0 + 240, 40))
		# List: heads and names, narrower.
		_v3_column(Rect2(x0 + 20, 90, 300, 900), "PERSONNAGE", false)
		var chosen := 0 if p == 0 else 2
		for n in 7:
			_v3_row(Rect2(x0 + 34, 146 + n * 118.0, 272, 104), n, n == chosen, n == 5)
		# Right: look on top, then weapon (and seal for player 1).
		_v3_column(Rect2(x0 + 340, 90, 600, 900), "", false)
		_tex(_card_path(chosen), Rect2(x0 + 400, 100, 300, 360))
		_label(HEROES[chosen][1].to_upper(), 40, Color("ff6b6b") if p == 0 else Color("6fb6ff"), Vector2(x0 + 700, 140), 0.0,
			HORIZONTAL_ALIGNMENT_LEFT, true)
		_stat_bars(Vector2(x0 + 700, 210), 220, [0.55, 0.7, 0.62, 0.78])
		_v3_looks(Vector2(x0 + 640, 500), p == 1, p == 0)
		if p == 0:
			_label("ARME", 30, CYAN, Vector2(x0 + 364, 556), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
			_v2_weapon_card(Rect2(x0 + 364, 600, 560, 92), V2_WEAPONS[0], false)
			_panel(Rect2(x0 + 364, 600, 560, 92), Color(0, 0, 0, 0), Color.WHITE, 4, 18)
			_label("Sceau", 22, MUTED, Vector2(x0 + 364, 706))
			for i in 6:
				_v2_seal(Rect2(x0 + 364 + i * 94.0, 738, 86, 80), i, "selected" if i == 1 else ("locked" if i > 2 else ""))
			_button(Rect2(x0 + 520, 860, 300, 90), "JOUER", "cta", 44)
		else:
			_label("ARME", 30, MUTED, Vector2(x0 + 364, 556), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
			_label("Valide l'apparence pour choisir l'arme.", 22, MUTED, Vector2(x0 + 364, 606))
	_line(Vector2(960, 0), Vector2(960, H), Color(BORDER, 0.9), 6.0)


# --- character select v4: turntable of looks, stone platform (2026-10-08) -----------

## Backdrop without the big floor glow: night gradient and a faint rune seal only.
func _v4_backdrop(center: Vector2) -> void:
	_gradient()
	_tex("res://art_source/ai/decor/decal_rune_circle.png", Rect2(center - Vector2(420, 420), Vector2(840, 840)),
		Rect2(), Color(VIOLET, 0.16))


## Flat ellipse (ring node squashed vertically).
func _ellipse(center: Vector2, rx: float, ry: float, fill: Color, border: Color, width: float) -> void:
	var node := Node2D.new()
	node.set_script(preload("res://src/debug/mockup_ring.gd"))
	node.set("center", Vector2.ZERO)
	node.set("radius", rx)
	node.set("color", border)
	node.set("width", width)
	node.set("start", 0.0)
	node.set("sweep", TAU)
	node.set("fill", fill)
	node.position = center
	node.scale = Vector2(1.0, ry / rx)
	_root.add_child(node)


## Stone platform the hero stands on: a thick disc (side then top), rune glow on top.
func _platform(center: Vector2, rx: float) -> void:
	var ry := rx * 0.26
	_ellipse(center + Vector2(0, ry * 0.7), rx, ry, Color("221a3a"), BORDER, 6.0)
	_panel(Rect2(center.x - rx, center.y, rx * 2.0, ry * 0.7), Color("221a3a"), Color(0, 0, 0, 0), 0, 0)
	_ellipse(center, rx, ry, Color("3a2f62"), BORDER, 6.0)
	_ellipse(center, rx * 0.78, ry * 0.78, Color(0, 0, 0, 0), Color(CYAN, 0.55), 4.0)
	_ellipse(center, rx * 0.5, ry * 0.5, Color(0, 0, 0, 0), Color(VIOLET, 0.6), 3.0)


## Turntable: the current look in front on the platform, the next one darker and
## smaller behind (turned away to the right), arrows on both sides, a dot per look.
func _turntable(center: Vector2, height: float, front: String, back: String, focused: bool, dots: int = 2) -> void:
	var w := height * 0.67
	_platform(center + Vector2(0, height * 0.02), w * 0.62)
	var behind := Rect2(center + Vector2(w * 0.08, -height * 0.86), Vector2(w * 0.78, height * 0.78))
	_tex(back, behind, Rect2(), Color(0.32, 0.27, 0.48, 0.85))
	_tex(front, Rect2(center + Vector2(-w * 0.5, -height), Vector2(w, height)))
	var arrow := CYAN if focused else MUTED
	for side in [-1.0, 1.0]:
		var p := center + Vector2(side * (w * 0.62 + 40.0), -height * 0.45)
		_ring(p, 30.0, BORDER, 4.0, 0.0, TAU, Color("4a2a86") if focused else PANEL)
		_label("▶" if side > 0.0 else "◀", 30, arrow, p - Vector2(30, 22), 60, HORIZONTAL_ALIGNMENT_CENTER)
	for d in dots:
		_ring(center + Vector2((d - (dots - 1) * 0.5) * 26.0, height * 0.28), 7.0, BORDER, 2.0, 0.0, TAU,
			CYAN if d == 0 else Color(MUTED, 0.5))


## Hunter row with a long name shrunk to fit.
func _v4_row(rect: Rect2, index: int, focused: bool, locked: bool = false) -> void:
	_panel(rect, Color("4a2a86") if focused else Color(PANEL, 0.9), CYAN if focused else BORDER, 4, 16)
	var head := rect.size.y - 16.0
	_tex(_card_path(index), Rect2(rect.position + Vector2(8, 8), Vector2(head, head)), Rect2(72, 8, 368, 368),
		Color(0.18, 0.15, 0.3, 1) if locked else Color.WHITE)
	var name: String = HEROES[index][1] if not locked else "🔒 ???"
	var room := rect.size.x - head - 36.0
	var size := mini(int(rect.size.y * 0.3), int(room / (name.length() * 0.52)))
	_label(name, size, TEXT if not locked else MUTED, rect.position + Vector2(head + 24, rect.size.y * 0.5 - size * 0.7))


const ALT_CARDS := ["gunslinger_m_card", "mage_m_card", "berserker_m_card", "ronin_m_card", "assassin_f_card",
	"merchant_m_card", "drifter_m_card"]


func _alt_path(index: int) -> String:
	return "res://assets/characters/cards/%s.png" % ALT_CARDS[index]


## Solo: PERSONNAGES list, turntable in the middle (lit: the look step), ARMES.
func _screen_select_v4() -> void:
	_v4_backdrop(Vector2(860, 470))
	_v2_back()
	_label("CHOISIS TON PERSONNAGE", 56, CYAN, Vector2(240, 30), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_v3_column(Rect2(40, 120, 420, 860), "PERSONNAGES", false)
	_v3_column(Rect2(490, 120, 760, 860), "", true)
	_v3_column(Rect2(1280, 120, 600, 860), "ARMES", false)
	for n in 7:
		_v4_row(Rect2(60, 180 + n * 110.0, 380, 96), n, n == 0, n == 5)
	_turntable(Vector2(870, 640), 480.0, _card_path(0), _alt_path(0), true)
	_label(HEROES[0][1].to_upper(), 52, Color("ff6b6b"), Vector2(520, 700), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(HEROES[0][2], 22, TEXT, Vector2(520, 764), 700)
	_stat_bars(Vector2(520, 800), 700, [0.55, 0.7, 0.62, 0.78])
	_v2_weapon_card(Rect2(1300, 190, 560, 104), V2_WEAPONS[0], false)
	_v2_weapon_card(Rect2(1300, 306, 560, 104), V2_WEAPONS[1], false)
	_label("Sceau", 26, MUTED, Vector2(1300, 428))
	for i in 6:
		_v2_seal(Rect2(1300 + (i % 3) * 188.0, 466 + (i / 3) * 118.0, 176, 104), i,
			"selected" if i == 1 else ("locked" if i > 2 else ""))
	_label("Fer · Temple englouti", 28, SEAL_HEAT[1], Vector2(1300, 712))
	_button(Rect2(1340, 840, 480, 110), "JOUER", "cta", 52)
	_hints([["A", "Valider", GO], ["B", "Retour", BAD], ["◀ ▶", "Tourner", GOLD]])


## Coop: two columns per half, same turntable and platform, smaller.
func _screen_select_v4_coop() -> void:
	_gradient()
	for p in 2:
		var x0 := 960.0 * p
		_label("JOUEUR %d" % (p + 1), 44, RunPlayer.COLORS[p], Vector2(x0 + 30, 22), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
		_label("Manette %d" % (p + 1), 20, MUTED, Vector2(x0 + 240, 40))
		_v3_column(Rect2(x0 + 20, 90, 300, 900), "PERSONNAGES", false)
		var chosen := 0 if p == 0 else 2
		for n in 7:
			_v4_row(Rect2(x0 + 34, 146 + n * 118.0, 272, 104), n, n == chosen, n == 5)
		_v3_column(Rect2(x0 + 340, 90, 600, 900), "", p == 1)
		_turntable(Vector2(x0 + 560, 470), 340.0, _card_path(chosen), _alt_path(chosen), p == 1)
		_label(HEROES[chosen][1].to_upper(), 36, Color("ff6b6b") if p == 0 else Color("6fb6ff"), Vector2(x0 + 740, 140), 0.0,
			HORIZONTAL_ALIGNMENT_LEFT, true)
		for k in 4:
			var names := ["PV", "Dégâts", "Vitesse", "Portée"]
			_label(names[k], 20, MUTED, Vector2(x0 + 740, 196 + k * 34.0))
			_panel(Rect2(x0 + 830, 202 + k * 34.0, 90, 14), PANEL_DARK, BORDER, 2, 7)
			_panel(Rect2(x0 + 830, 202 + k * 34.0, 90 * [0.55, 0.7, 0.62, 0.78][k], 14), CYAN, BORDER, 2, 7)
		if p == 0:
			_label("ARMES", 30, CYAN, Vector2(x0 + 364, 556), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
			_v2_weapon_card(Rect2(x0 + 364, 600, 560, 92), V2_WEAPONS[0], false)
			_panel(Rect2(x0 + 364, 600, 560, 92), Color(0, 0, 0, 0), Color.WHITE, 4, 18)
			_label("Sceau", 22, MUTED, Vector2(x0 + 364, 706))
			for i in 6:
				_v2_seal(Rect2(x0 + 364 + i * 94.0, 738, 86, 80), i, "selected" if i == 1 else ("locked" if i > 2 else ""))
			_button(Rect2(x0 + 520, 860, 300, 90), "JOUER", "cta", 44)
		else:
			_label("ARMES", 30, MUTED, Vector2(x0 + 364, 556), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
			_label("Valide l'apparence pour choisir l'arme.", 22, MUTED, Vector2(x0 + 364, 606))
	_line(Vector2(960, 0), Vector2(960, H), Color(BORDER, 0.9), 6.0)


# --- character select v5: three platforms to choose from (2026-10-08) ----------------

## [image, label, center of the top surface as a fraction of the image height].
const DALLES := [["res://art_tests/interface/dalles/1_pierre_runique.png", "1 · Pierre runique", 0.40],
	["res://art_tests/interface/dalles/2_obsidienne_portail.png", "2 · Obsidienne du portail", 0.44],
	["res://art_tests/interface/dalles/3_sceau_bronze.png", "3 · Sceau de la guilde", 0.37]]


## Turntable on a generated platform: the feet of the front look stand in the middle
## of the platform's top surface, with a contact shadow; the other look behind.
func _turntable_on(center: Vector2, height: float, front: String, back: String, dalle: Array) -> void:
	var dw := height * 0.95
	var dh := dw * 1024.0 / 1536.0
	var feet := center
	_tex(dalle[0], Rect2(feet - Vector2(dw * 0.5, dh * dalle[2]), Vector2(dw, dh)))
	_ellipse(feet + Vector2(height * 0.16, -height * 0.02), height * 0.15, height * 0.035, Color(0, 0, 0, 0.35),
		Color(0, 0, 0, 0), 0.0)
	var w := height * 0.67
	# Card art: the feet are at 98 % of the image height.
	_tex(back, Rect2(feet + Vector2(w * 0.12, -height * 0.84), Vector2(w * 0.82, height * 0.82)), Rect2(),
		Color(0.32, 0.27, 0.48, 0.85))
	_ellipse(feet + Vector2(0, -height * 0.005), height * 0.17, height * 0.04, Color(0, 0, 0, 0.4), Color(0, 0, 0, 0), 0.0)
	_tex(front, Rect2(feet + Vector2(-w * 0.5, -height * 0.98), Vector2(w, height)))
	for side in [-1.0, 1.0]:
		var p := feet + Vector2(side * (w * 0.62 + 40.0), -height * 0.45)
		_ring(p, 30.0, BORDER, 4.0, 0.0, TAU, Color("4a2a86"))
		_label("▶" if side > 0.0 else "◀", 30, CYAN, p - Vector2(30, 22), 60, HORIZONTAL_ALIGNMENT_CENTER)


## Three middle panels side by side, one per platform.
func _screen_select_v5_dalles() -> void:
	_v4_backdrop(Vector2(960, 470))
	_label("TROIS DALLES AU CHOIX", 56, CYAN, Vector2(0, 26), W, HORIZONTAL_ALIGNMENT_CENTER, true)
	for k in 3:
		var r := Rect2(40 + k * 625.0, 120, 590, 900)
		_v3_column(r, "", k == 0)
		_turntable_on(Vector2(r.position.x + r.size.x * 0.5, 680), 480.0, _card_path(0), _alt_path(0), DALLES[k])
		_label(DALLES[k][1], 34, TEXT, Vector2(r.position.x, 880), r.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)


# --- character select v6: middle between the feet, turntable arrows (2026-10-08) -----

## One hero on the stone platform, placed by CharacterSelect.feet_anchor (middle between
## the feet); red dots on the feet found, cyan cross on their middle, yellow ring on the
## middle of the platform's top.
func _v6_hero(center: Vector2, height: float, card: String) -> void:
	var platform := load("res://assets/ui/select/platform_stone.png") as Texture2D
	var pw := height * 0.66
	var ph := pw * platform.get_height() / float(platform.get_width())
	_tex("res://assets/ui/select/platform_stone.png",
		Rect2(center - Vector2(pw * CharacterSelect.PLATFORM_TOP.x, ph * CharacterSelect.PLATFORM_TOP.y), Vector2(pw, ph)))
	var texture := load(card) as Texture2D
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	var anchor := CharacterSelect.feet_anchor(texture)
	var w := height * texture.get_width() / float(texture.get_height())
	var origin := center - Vector2(w * anchor.x, height * anchor.y)
	_tex(card, Rect2(origin, Vector2(w, height)))
	var scale := height / image.get_height()
	for foot in CharacterSelect.feet_points(image):
		_ring(origin + foot * scale, 7.0, BORDER, 2.0, 0.0, TAU, Color("ff3b3b"))
	_ring(center, 13.0, GOLD, 3.0)
	_line(center - Vector2(16, 0), center + Vector2(16, 0), CYAN, 4.0)
	_line(center - Vector2(0, 16), center + Vector2(0, 16), CYAN, 4.0)


## A: thin chevrons with a glow, no button plate.
func _v6_arrows_a(center: Vector2, gap: float) -> void:
	for side in [-1.0, 1.0]:
		var p := center + Vector2(side * gap, 0)
		_label("❮" if side < 0.0 else "❯", 72, Color(CYAN, 0.25), p - Vector2(34, 54), 68, HORIZONTAL_ALIGNMENT_CENTER)
		_label("❮" if side < 0.0 else "❯", 60, CYAN, p - Vector2(30, 46), 60, HORIZONTAL_ALIGNMENT_CENTER)


## B: rotation arcs around the platform (it turns), small arrow heads at their ends.
func _v6_arrows_b(center: Vector2, rx: float) -> void:
	var node := Node2D.new()
	node.set_script(preload("res://src/debug/mockup_ring.gd"))
	node.set("center", Vector2.ZERO)
	node.set("radius", rx)
	node.set("color", Color(CYAN, 0.9))
	node.set("width", 5.0)
	node.set("start", PI * 0.15)
	node.set("sweep", PI * 0.7)
	node.position = center
	node.scale = Vector2(1.0, 0.3)
	_root.add_child(node)
	var node2 := Node2D.new()
	node2.set_script(preload("res://src/debug/mockup_ring.gd"))
	node2.set("center", Vector2.ZERO)
	node2.set("radius", rx)
	node2.set("color", Color(CYAN, 0.9))
	node2.set("width", 5.0)
	node2.set("start", PI * 1.15)
	node2.set("sweep", PI * 0.7)
	node2.position = center
	node2.scale = Vector2(1.0, 0.3)
	_root.add_child(node2)
	_label("◀", 30, CYAN, center + Vector2(-rx - 20, -24))
	_label("▶", 30, CYAN, center + Vector2(rx - 12, -24))


## C: two small rune stones set into the platform's rim, an arrow carved in each.
func _v6_arrows_c(center: Vector2, gap: float) -> void:
	for side in [-1.0, 1.0]:
		var p := center + Vector2(side * gap, 0)
		_panel(Rect2(p - Vector2(30, 26), Vector2(60, 52)), Color("8a8aa0"), BORDER, 4, 12)
		_panel(Rect2(p - Vector2(24, 20), Vector2(48, 40)), Color("6f6f88"), Color(0, 0, 0, 0), 0, 8)
		_label("◀" if side < 0.0 else "▶", 26, CYAN, p - Vector2(30, 20), 60, HORIZONTAL_ALIGNMENT_CENTER)


func _screen_select_v6() -> void:
	_v4_backdrop(Vector2(960, 300))
	_label("LE MILIEU DES DEUX PIEDS AU CENTRE DE LA DALLE", 40, CYAN, Vector2(0, 16), W, HORIZONTAL_ALIGNMENT_CENTER, true)
	var cards := ["gunslinger_card", "berserker_m_card", "ronin_card"]
	for k in 3:
		_v6_hero(Vector2(330 + k * 630.0, 520), 420.0, "res://assets/characters/cards/%s.png" % cards[k])
	_label("● pieds repérés   ✚ milieu des pieds   ◯ centre de la dalle", 24, TEXT, Vector2(0, 600), W,
		HORIZONTAL_ALIGNMENT_CENTER)
	_label("FLÈCHES DU PLATEAU", 36, CYAN, Vector2(0, 650), W, HORIZONTAL_ALIGNMENT_CENTER, true)
	var names := ["A · Chevrons lumineux", "B · Arcs de rotation", "C · Pierres runiques"]
	for k in 3:
		var c := Vector2(330 + k * 630.0, 880)
		var platform := Rect2(c - Vector2(150, 70), Vector2(300, 198))
		_tex("res://assets/ui/select/platform_stone.png", platform)
		match k:
			0:
				_v6_arrows_a(c + Vector2(0, -10), 210.0)
			1:
				_v6_arrows_b(c + Vector2(0, 40), 190.0)
			2:
				_v6_arrows_c(c + Vector2(0, 60), 175.0)
		_label(names[k], 26, TEXT, Vector2(c.x - 300, 1030), 600, HORIZONTAL_ALIGNMENT_CENTER)


# --- character select v7 + danger screen (2026-10-08) --------------------------------
# Dev's notes: no violet rune behind the hero, the hero much bigger; the seal moves to
# its own screen once every player has picked a character.

const GATE_BG := "res://art_tests/interface/danger/bg_gate.png"
## Seal metals, Copper to Astral: [rim, face].
const SEAL_METAL := [[Color("d9874a"), Color("8a4a24")], [Color("b8c0cc"), Color("5a6270")],
	[Color("eef2f8"), Color("9aa4b4")], [Color("ffd84d"), Color("b8860b")], [Color("b86bff"), Color("241a3a")],
	[Color("8fe9ff"), Color("2b5c8a")]]
const SEAL_NAMES := ["Cuivre", "Fer", "Argent", "Or", "Obsidienne", "Astral"]
const SEAL_FULL := ["Sceau de Cuivre", "Sceau de Fer", "Sceau d'Argent", "Sceau d'Or", "Sceau d'Obsidienne", "Sceau Astral"]
const SEAL_FX := ["La partie normale", "Élites : 6 %", "Ennemis +15 % PV et dégâts", "+20 % d'ennemis, groupes plus gros",
	"Ennemis +30 % PV et dégâts", "Deux boss finaux"]
const SEAL_PLACES := ["Donjon de pierre", "Temple englouti", "Forêt gelée", "Citadelle infernale", "Ruche souterraine",
	"Antre du dragon"]
## Socket centers of the six seals on the generated gate (1536x1024 image coordinates),
## in order: up the left side of the arch, then down the right side.
const GATE_SOCKETS := [Vector2(565, 418), Vector2(578, 288), Vector2(661, 190), Vector2(866, 190), Vector2(951, 288),
	Vector2(965, 418)]


## Hero standing on the stone platform (real anchor of the game: middle between the feet).
func _v7_hero(feet: Vector2, height: float, card: String, back: String = "") -> void:
	var platform := load("res://assets/ui/select/platform_stone.png") as Texture2D
	var pw := height * 0.78
	var ph := pw * platform.get_height() / float(platform.get_width())
	_tex("res://assets/ui/select/platform_stone.png",
		Rect2(feet - Vector2(pw * CharacterSelect.PLATFORM_TOP.x, ph * CharacterSelect.PLATFORM_TOP.y), Vector2(pw, ph)))
	if back != "":
		var bt := load(back) as Texture2D
		var bw := height * 0.8 * bt.get_width() / float(bt.get_height())
		_tex(back, Rect2(feet + Vector2(pw * 0.08, -height * 0.86), Vector2(bw, height * 0.8)), Rect2(),
			Color(0.32, 0.27, 0.48, 0.85))
	var texture := load(card) as Texture2D
	var anchor := CharacterSelect.feet_anchor(texture)
	var w := height * texture.get_width() / float(texture.get_height())
	_tex(card, Rect2(feet - Vector2(w * anchor.x, height * anchor.y), Vector2(w, height)))
	for side in [-1.0, 1.0]:
		var p := feet + Vector2(side * pw * 0.62, -height * 0.45)
		_label("❮" if side < 0.0 else "❯", 64, Color(CYAN, 0.25), p - Vector2(36, 56), 72, HORIZONTAL_ALIGNMENT_CENTER)
		_label("❮" if side < 0.0 else "❯", 54, CYAN, p - Vector2(30, 46), 60, HORIZONTAL_ALIGNMENT_CENTER)
	for d in 2:
		_ring(feet + Vector2((d - 0.5) * 26.0, ph * 0.72), 7.0, BORDER, 2.0, 0.0, TAU, CYAN if d == 0 else Color(MUTED, 0.5))


func _v7_info(pos: Vector2, width: float, index: int, size: int) -> void:
	_label(HEROES[index][1].to_upper(), size, CYAN, pos, 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(HEROES[index][2], int(size * 0.42), TEXT, pos + Vector2(0, size * 1.15), width)
	var names := ["PV", "Dégâts", "Vitesse", "Portée"]
	var colors := [Color("ff6673"), Color("ffb347"), Color("66f2ff"), Color("b86bff")]
	var values := [0.55, 0.7, 0.62, 0.78]
	var y0 := pos.y + size * 2.4
	for k in 4:
		var x := pos.x + (k % 2) * width * 0.5
		var y := y0 + (k / 2) * size * 0.7
		_label(names[k], int(size * 0.38), MUTED, Vector2(x, y))
		_panel(Rect2(x + width * 0.17, y + size * 0.1, width * 0.25, size * 0.24), PANEL_DARK, BORDER, 2, 7)
		_panel(Rect2(x + width * 0.17, y + size * 0.1, width * 0.25 * values[k], size * 0.24), colors[k], BORDER, 2, 7)


## Solo: the middle column only holds the hero (bigger, no rune behind); weapons at
## right, then "Valider" opens the seal screen.
func _screen_select_v7_solo() -> void:
	_gradient()
	_v2_back()
	_label("CHOISIS TON PERSONNAGE", 56, CYAN, Vector2(240, 30), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_v3_column(Rect2(40, 120, 420, 860), "PERSONNAGES", false)
	_v3_column(Rect2(490, 120, 800, 860), "", false)
	_v3_column(Rect2(1320, 120, 560, 860), "ARMES", true)
	for n in 7:
		_v4_row(Rect2(60, 180 + n * 110.0, 380, 96), n, n == 3, n == 5)
	_v7_hero(Vector2(890, 660), 520.0, _card_path(3), _alt_path(3))
	_v7_info(Vector2(530, 760), 720, 3, 50)
	_v2_weapon_card(Rect2(1340, 190, 520, 104), ["steel_katana", "Katana d'acier", "Taillade rapide devant soi."], true)
	_v2_weapon_card(Rect2(1340, 306, 520, 104), ["spear", "Lance", "Estoc à longue portée."], false)
	_button(Rect2(1380, 780, 440, 104), "VALIDER", "cta", 48)
	_label("Le sceau se choisit à l'écran suivant", 22, MUTED, Vector2(1340, 900), 520, HORIZONTAL_ALIGNMENT_CENTER)
	_hints([["A", "Choisir", GO], ["B", "Retour", BAD], ["◀ ▶", "Apparence", GOLD]])


## Coop A: list at left of each half, the hero fills the rest, weapons under the info.
func _screen_select_v7_coop_a() -> void:
	_gradient()
	for p in 2:
		var x0 := 960.0 * p
		var chosen := 3 if p == 0 else 1
		_label("JOUEUR %d" % (p + 1), 44, RunPlayer.COLORS[p], Vector2(x0 + 30, 22), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
		_v3_column(Rect2(x0 + 20, 90, 220, 960), "", false)
		for n in 7:
			var row := Rect2(x0 + 30, 104 + n * 134.0, 200, 122)
			_panel(row, Color("4a2a86") if n == chosen else Color(PANEL, 0.9), CYAN if n == chosen else BORDER,
				4, 16)
			_tex(_card_path(n), Rect2(row.position + Vector2(50, 6), Vector2(100, 84)), Rect2(72, 8, 368, 310),
				Color(0.18, 0.15, 0.3, 1) if n == 5 else Color.WHITE)
			_label(HEROES[n][1] if n != 5 else "🔒 ???", 20, TEXT if n != 5 else MUTED, row.position + Vector2(0, 90),
				200, HORIZONTAL_ALIGNMENT_CENTER)
		_v3_column(Rect2(x0 + 256, 90, 684, 960), "", false)
		_v7_hero(Vector2(x0 + 598, 520), 400.0, _card_path(chosen), _alt_path(chosen))
		_v7_info(Vector2(x0 + 286, 610), 620, chosen, 40)
		if p == 0:
			_v2_weapon_card(Rect2(x0 + 280, 812, 636, 88), ["steel_katana", "Katana d'acier", "Taillade rapide."], true)
			_v2_weapon_card(Rect2(x0 + 280, 910, 636, 88), ["spear", "Lance", "Estoc à longue portée."], false)
		else:
			_panel(Rect2(x0 + 280, 830, 636, 150), Color("1f6b3a"), GO, 5, 24)
			_label("PRÊT ✔", 56, Color.WHITE, Vector2(x0 + 280, 860), 636, HORIZONTAL_ALIGNMENT_CENTER, true)
	_line(Vector2(960, 0), Vector2(960, H), Color(BORDER, 0.9), 6.0)


## Coop B: heads in a strip at the top of each half, the hero huge at left, info and
## weapons at right.
func _screen_select_v7_coop_b() -> void:
	_gradient()
	for p in 2:
		var x0 := 960.0 * p
		var chosen := 3 if p == 0 else 1
		_label("JOUEUR %d" % (p + 1), 40, RunPlayer.COLORS[p], Vector2(x0 + 30, 18), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
		for n in 7:
			var r := Rect2(x0 + 30 + n * 130.0, 80, 118, 118)
			_panel(r, Color("4a2a86") if n == chosen else Color(PANEL, 0.9), CYAN if n == chosen else BORDER,
				5 if n == chosen else 3, 16)
			_tex(_card_path(n), r.grow(-8), Rect2(72, 8, 368, 368),
				Color(0.18, 0.15, 0.3, 1) if n == 5 else Color.WHITE)
		_v3_column(Rect2(x0 + 20, 216, 920, 834), "", false)
		_v7_hero(Vector2(x0 + 270, 800), 480.0, _card_path(chosen), _alt_path(chosen))
		_v7_info(Vector2(x0 + 520, 250), 400, chosen, 40)
		_label("ARMES", 30, CYAN, Vector2(x0 + 520, 470), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
		if p == 0:
			_v2_weapon_card(Rect2(x0 + 520, 516, 400, 96), ["steel_katana", "Katana d'acier", "Taillade rapide."], true)
			_v2_weapon_card(Rect2(x0 + 520, 624, 400, 96), ["spear", "Lance", "Estoc."], false)
		else:
			_v2_weapon_card(Rect2(x0 + 520, 516, 400, 96), ["rapier", "Rapière", "Estocs rapides."], false)
			_panel(Rect2(x0 + 520, 860, 400, 130), Color("1f6b3a"), GO, 5, 24)
			_label("PRÊT ✔", 52, Color.WHITE, Vector2(x0 + 520, 884), 400, HORIZONTAL_ALIGNMENT_CENTER, true)
	_line(Vector2(960, 0), Vector2(960, H), Color(BORDER, 0.9), 6.0)


## Round seal medallion: metal rim, numeral; `state`: "", "selected", "locked".
func _seal(center: Vector2, radius: float, level: int, state: String) -> void:
	var rim: Color = SEAL_METAL[level][0]
	var face: Color = SEAL_METAL[level][1]
	if state == "locked":
		_ring(center, radius, BORDER, 6.0, 0.0, TAU, Color("1a1430"))
		_ring(center, radius * 0.82, Color(MUTED, 0.25), 3.0)
		_label("🔒", int(radius * 0.7), Color(MUTED, 0.7), center - Vector2(radius, radius * 0.5), radius * 2.0,
			HORIZONTAL_ALIGNMENT_CENTER)
		return
	if state == "selected":
		for k in 3:
			_ring(center, radius * (1.18 + k * 0.12), Color(rim, 0.35 - k * 0.1), 8.0)
	_ring(center, radius, BORDER, 6.0, 0.0, TAU, rim)
	_ring(center, radius * 0.8, BORDER, 4.0, 0.0, TAU, face)
	_label(["I", "II", "III", "IV", "V", "VI"][level], int(radius * 0.72), rim,
		center - Vector2(radius, radius * 0.55), radius * 2.0, HORIZONTAL_ALIGNMENT_CENTER, true)


func _gate_bg(dim: float = 0.0) -> void:
	_tex(GATE_BG, Rect2(0, -100, W, 1280))
	if dim > 0.0:
		var c := ColorRect.new()
		c.color = Color(0.03, 0.02, 0.08, dim)
		c.size = Vector2(W, H)
		_root.add_child(c)


func _gate_socket(index: int) -> Vector2:
	return GATE_SOCKETS[index] * 1.25 - Vector2(0, 100)


## Seal details: name in its metal, effect, place, reward.
func _seal_panel(rect: Rect2, level: int, silhouettes: bool = false) -> void:
	_panel(rect, Color(PANEL_DARK, 0.92), SEAL_METAL[level][0], 5, 24)
	var x := rect.position.x + 32
	_label(SEAL_FULL[level].to_upper(), 52, SEAL_METAL[level][0], Vector2(x, rect.position.y + 18), 0.0,
		HORIZONTAL_ALIGNMENT_LEFT, true)
	_label("☠ " + SEAL_FX[level], 28, TEXT, Vector2(x, rect.position.y + 92))
	_label("Lieu : " + SEAL_PLACES[level], 26, MUTED, Vector2(x, rect.position.y + 134))
	if not silhouettes:
		_label("Récompense : Coffre doré + 2 objets", 26, GOLD, Vector2(x, rect.position.y + 172))
		return
	# Rewards still to win: dark silhouettes of their icons (the game's own shader).
	_label("À gagner", 24, GOLD, Vector2(rect.end.x - 330, rect.position.y + 26), 300, HORIZONTAL_ALIGNMENT_CENTER)
	var rewards := SealSelect.seal_rewards(level)
	var paths: Array[String] = []
	for target in rewards:
		paths.append((target.get(&"icon") as Texture2D).resource_path)
	if paths.is_empty():
		paths = ["res://assets/icons/weapons/warhammer.png", "res://assets/icons/weapons/scythe.png",
			"res://assets/icons/weapons/meteor_grimoire.png"]
	for k in mini(paths.size(), 3):
		var box := Rect2(rect.end.x - 340 + k * 104.0, rect.position.y + 70, 96, 96)
		_panel(box, Color(0.06, 0.04, 0.14, 0.9), Color(GOLD, 0.6), 3, 14)
		var icon := _tex(paths[k], box.grow(-10))
		icon.material = SealSelect.silhouette_material()
		_label("?", 34, Color(GOLD, 0.9), box.position + Vector2(0, 20), box.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)


func _ready_tags(coop: bool) -> void:
	var heroes := [3, 1] if coop else [3]
	for p in heroes.size():
		var x := 40.0 if p == 0 else W - 300.0
		var r := Rect2(x, H - 250, 260, 150)
		_panel(r, Color(PANEL_DARK, 0.9), RunPlayer.COLORS[p] if coop else CYAN, 4, 18)
		_tex(_card_path(heroes[p]), Rect2(r.position + Vector2(10, 10), Vector2(130, 130)), Rect2(72, 8, 368, 368))
		_label(HEROES[heroes[p]][1], 22, TEXT, r.position + Vector2(146, 30), 110)
		_label("PRÊT ✔", 24, GOOD, r.position + Vector2(146, 96))


## A: the seals sit in the six sockets of the gate (diegetic), details below.
func _screen_danger_a() -> void:
	_gate_bg()
	_v2_back()
	_label("CHOISIS TON SCEAU", 56, CYAN, Vector2(240, 30), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	for i in 6:
		_seal(_gate_socket(i), 54.0, i, "selected" if i == 3 else ("locked" if i > 3 else ""))
	_seal_panel(Rect2(560, 770, 800, 230), 3)
	_button(Rect2(1440, 820, 400, 120), "JOUER", "cta", 56)
	_ready_tags(false)
	_hints([["A", "Jouer", GO], ["B", "Retour", BAD], ["◀ ▶", "Sceau", GOLD]])


## B: a row of six big seals in front of the gate (dimmed), details under them.
func _screen_danger_b() -> void:
	_tex("res://art_tests/interface/danger/bg_gate_v2.png", Rect2(0, -100, W, 1280))
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.4)
	dim.size = Vector2(W, H)
	_root.add_child(dim)
	_v2_back()
	_title("CHOISIS TON SCEAU", 26, 64)
	for i in 6:
		var c := Vector2(360 + i * 240.0, 470)
		var state := "selected" if i == 3 else ("locked" if i > 3 else "")
		_seal(c, 96.0 if i == 3 else 80.0, i, state)
		_label(SEAL_NAMES[i] if i <= 3 else "???", 30, SEAL_METAL[i][0] if i <= 3 else MUTED, c + Vector2(-120, 112), 240,
			HORIZONTAL_ALIGNMENT_CENTER, true)
	_seal_panel(Rect2(410, 680, 1100, 230), 3, true)
	_button(Rect2(760, 930, 400, 100), "JOUER", "cta", 50)
	_hints([["A", "Jouer", GO], ["B", "Retour", BAD], ["◀ ▶", "Sceau", GOLD]])


## C: list of seal cards at left, the gate at right with the chosen seal glowing big.
func _screen_danger_c() -> void:
	_gate_bg()
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.08, 0.85)
	shade.size = Vector2(760, H)
	_root.add_child(shade)
	_v2_back()
	_label("CHOISIS TON SCEAU", 52, CYAN, Vector2(240, 32), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	for i in 6:
		var r := Rect2(40, 130 + i * 136.0, 680, 120)
		var locked := i > 3
		_panel(r, Color("4a2a86") if i == 3 else Color(PANEL, 0.92), SEAL_METAL[i][0] if i == 3 else BORDER,
			5 if i == 3 else 3, 18)
		_seal(r.position + Vector2(64, 60), 44.0, i, "locked" if locked else "")
		_label(SEAL_FULL[i] if not locked else "Sceau verrouillé", 32,
			SEAL_METAL[i][0] if not locked else MUTED, r.position + Vector2(130, 14), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
		_label(SEAL_FX[i] if not locked else "Gagne le sceau précédent avec ce chasseur", 22,
			TEXT if not locked else MUTED, r.position + Vector2(130, 70), 540)
	_seal(Vector2(1340, 420), 130.0, 3, "selected")
	_label("Citadelle infernale", 40, SEAL_METAL[3][0], Vector2(940, 600), 800, HORIZONTAL_ALIGNMENT_CENTER, true)
	_label("Récompense : Coffre doré + 2 objets", 28, GOLD, Vector2(940, 660), 800, HORIZONTAL_ALIGNMENT_CENTER)
	_button(Rect2(1140, 860, 400, 110), "JOUER", "cta", 52)
	_hints([["A", "Jouer", GO], ["B", "Retour", BAD], ["▲ ▼", "Sceau", GOLD]])


## Coop (on A): one shared screen, full width; player 1 picks, both heroes shown ready;
## seals above what player 2's hunter has won are locked with the reason.
func _screen_danger_coop() -> void:
	_gate_bg()
	_v2_back()
	_label("CHOISISSEZ VOTRE SCEAU", 56, CYAN, Vector2(240, 30), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	for i in 6:
		_seal(_gate_socket(i), 54.0, i, "selected" if i == 2 else ("locked" if i > 2 else ""))
	_seal_panel(Rect2(560, 740, 800, 230), 2)
	_label("Sceau suivant : à gagner par la Mage (joueur 2)", 22, MUTED, Vector2(560, 984), 800,
		HORIZONTAL_ALIGNMENT_CENTER)
	_ready_tags(true)
	_button(Rect2(1440, 560, 400, 110), "JOUER", "cta", 52)
	_label("Joueur 1 choisit", 22, RunPlayer.COLORS[0], Vector2(1440, 680), 400, HORIZONTAL_ALIGNMENT_CENTER)
