extends Node
## Debug tool: three proposals for a full UI re-theme (ornaments, palette, typography),
## each drawn on one 1920x1080 sheet with the same content: main menu, shop, level-up
## and the in-run HUD strip, built from the real game art. Throwaway (nothing here is
## used by the game): the dev picks one, then the real theme (UiTheme) is rebuilt on it.
## Fonts are read at runtime from art_tests/ui_themes/fonts (OFL, not in the project yet).
## Usage: Godot.exe --path . res://src/debug/theme_mockup.tscn -- --theme=a|b|c --out=<png>

const W := 1920.0
const H := 1080.0
const FONT_DIR := "res://art_tests/ui_themes/fonts/"

## Palettes and fonts of the three proposals.
const THEMES := {
	"a": {
		"name": "ROYAUME SANGLANT", "tag": "Gothique · rouge sang · or vieilli",
		"bg1": Color("0b0508"), "bg2": Color("2a0a12"), "panel": Color("170a0f"), "panel2": Color("26101a"),
		"line": Color("c9a24b"), "line2": Color("7a1426"), "text": Color("f1e6d0"), "muted": Color("a9937a"),
		"accent": Color("e63946"), "price": Color("ffd166"), "cta1": Color("a31621"), "cta2": Color("5a0b14"),
		"title": "CinzelDecorative-Bold.ttf", "body": "CrimsonPro.ttf", "style": 0, "weight": 600,
	},
	"b": {
		"name": "PORTAIL ARCANIQUE", "tag": "Violet nuit · cyan · argent",
		"bg1": Color("0a0820"), "bg2": Color("241250"), "panel": Color("140f33"), "panel2": Color("211652"),
		"line": Color("8ee9ff"), "line2": Color("7b3ff2"), "text": Color("eef0ff"), "muted": Color("a99fd6"),
		"accent": Color("66f2ff"), "price": Color("ffd94d"), "cta1": Color("8a4dff"), "cta2": Color("4a22a8"),
		"title": "Marcellus-Regular.ttf", "body": "Exo2.ttf", "style": 1, "weight": 600,
	},
	"c": {
		"name": "OBSIDIENNE ET OR", "tag": "Pierre noire · or antique · ambre",
		"bg1": Color("08090b"), "bg2": Color("1a1d22"), "panel": Color("101216"), "panel2": Color("1c2026"),
		"line": Color("d8a84a"), "line2": Color("5b4a2a"), "text": Color("ece7da"), "muted": Color("9a9484"),
		"accent": Color("ff9d2e"), "price": Color("ffcf5a"), "cta1": Color("c98a1a"), "cta2": Color("6b4708"),
		"title": "PirataOne-Regular.ttf", "body": "SourceSerif4.ttf", "style": 2, "weight": 600,
	},
}

const MENU := ["Jouer", "Coop locale", "Progression", "Boutique de skins", "Paramètres", "Quitter"]
const OFFERS := [["rage_potion", "Potion de régénération", "+1 Régénération", 12],
	["swift_rune", "Rune de célérité", "+6 % Vitesse d'attaque", 18],
	["", "Épée flamboyante", "Enflamme les ennemis", 20],
	["magnet_glove", "Gant de magnétite", "+40 Portée de ramassage", 10]]
const UPGRADES := [["magnet_glove", "Aimant", "+22 % Portée de ramassage"], ["swift_rune", "Frénésie", "+8 % Vitesse d'attaque"],
	["tracker_boots", "Esquive", "+5 % Esquive"], ["hunter_mark", "Précision", "+5 % Chance de critique"]]

var _t: Dictionary
var _root: Control
var _fonts: Dictionary = {}
var _out := "user://theme_mockup.png"


func _ready() -> void:
	var which := "a"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--theme="):
			which = arg.trim_prefix("--theme=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_t = THEMES[which]
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(1920, 1080)
	get_window().position = Vector2i(0, 0)
	_root = Control.new()
	_root.size = Vector2(W, H)
	add_child(_root)
	_build()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	print("theme mockup saved: ", _out)
	get_tree().quit()


# --- Helpers ------------------------------------------------------------------

func _font(key: String) -> Font:
	var file: String = _t[key]
	if not _fonts.has(file):
		var font := FontFile.new()
		font.load_dynamic_font(ProjectSettings.globalize_path(FONT_DIR + file))
		_fonts[file] = font
	var f: Font = _fonts[file]
	if key == "body":
		var variation := FontVariation.new()
		variation.base_font = f
		variation.variation_opentype = {"wght": _t["weight"]}
		return variation
	return f


func _label(text: String, size: int, color: Color, pos: Vector2, width: float = 0.0, align: int = HORIZONTAL_ALIGNMENT_LEFT,
		title: bool = false, outline: int = 0) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_override("font", _font("title" if title else "body"))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if outline > 0:
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("outline_size", outline)
	if width > 0.0:
		label.custom_minimum_size.x = width
		label.size.x = width
		label.horizontal_alignment = align
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(label)
	return label


func _tex(path: String, rect: Rect2, region: Rect2 = Rect2()) -> void:
	var rect_node := TextureRect.new()
	var texture: Texture2D = load(path)
	if region.size != Vector2.ZERO:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = region
		texture = atlas
	rect_node.texture = texture
	rect_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect_node.position = rect.position
	rect_node.size = rect.size
	_root.add_child(rect_node)


## A control drawn by `painter(control)`.
func _canvas(rect: Rect2, painter: Callable) -> Control:
	var c := Control.new()
	c.position = rect.position
	c.size = rect.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(painter.bind(c))
	_root.add_child(c)
	return c


# --- Ornaments ------------------------------------------------------------------

## Ornamented frame: fill, double line, and corners by style
## (0 gothic: diamond + brackets, 1 arcane: chamfered cut with glowing corners, 2 rivets).
func _frame(rect: Rect2, fill: Color, glow: bool = false, emphasis: float = 1.0) -> void:
	_canvas(rect, func(c: Control) -> void: _paint_frame(c, fill, glow, emphasis))


func _paint_frame(c: Control, fill: Color, glow: bool, emphasis: float) -> void:
	var r := Rect2(Vector2.ZERO, c.size)
	var line: Color = _t["line"]
	var line2: Color = _t["line2"]
	var style: int = _t["style"]
	var pts := _outline_points(r, style, 0.0)
	var inner := _outline_points(r.grow(-7.0), style, 0.0)
	c.draw_colored_polygon(pts, fill)
	if glow:
		c.draw_polyline(_close(pts), Color(line, 0.25), 9.0 * emphasis, true)
	c.draw_polyline(_close(pts), Color(line, 0.95), 2.5 * emphasis, true)
	c.draw_polyline(_close(inner), Color(line2, 0.9), 1.5, true)
	_corners(c, r, style, line, emphasis)


func _outline_points(r: Rect2, style: int, _unused: float) -> PackedVector2Array:
	var cut := 14.0 if style == 1 else (4.0 if style == 0 else 8.0)
	if style == 2:
		cut = 8.0
	return PackedVector2Array([
		r.position + Vector2(cut, 0), r.position + Vector2(r.size.x - cut, 0), r.position + Vector2(r.size.x, cut),
		r.position + Vector2(r.size.x, r.size.y - cut), r.position + Vector2(r.size.x - cut, r.size.y),
		r.position + Vector2(cut, r.size.y), r.position + Vector2(0, r.size.y - cut), r.position + Vector2(0, cut)])


func _close(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out


func _diamond(c: Control, at: Vector2, size: float, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -size), at + Vector2(size, 0), at + Vector2(0, size),
		at + Vector2(-size, 0)]), color)


func _corners(c: Control, r: Rect2, style: int, line: Color, emphasis: float) -> void:
	var s := minf(34.0, minf(r.size.x, r.size.y) * 0.25) * emphasis
	for corner in 4:
		var sx := -1.0 if corner % 2 == 1 else 1.0
		var sy := -1.0 if corner >= 2 else 1.0
		var origin := r.position + Vector2(0.0 if sx > 0 else r.size.x, 0.0 if sy > 0 else r.size.y)
		match style:
			0:  # gothic: an L bracket with a diamond at the tip and a small one on the corner
				var p := origin + Vector2(sx, sy) * 5.0
				c.draw_polyline(PackedVector2Array([p + Vector2(sx * s, 0), p, p + Vector2(0, sy * s)]), line, 3.0, true)
				_diamond(c, p + Vector2(sx * s, 0), 3.5, line)
				_diamond(c, p + Vector2(0, sy * s), 3.5, line)
				_diamond(c, p, 4.5, line)
			1:  # arcane: glowing node on the cut corner and two short rays along the edges
				var p := origin + Vector2(sx, sy) * 11.0
				c.draw_circle(p, 6.0 * emphasis, Color(line, 0.25))
				c.draw_circle(p, 3.0, line)
				c.draw_line(p + Vector2(sx * 8.0, 0), p + Vector2(sx * s, 0), Color(line, 0.8), 1.5, true)
				c.draw_line(p + Vector2(0, sy * 8.0), p + Vector2(0, sy * s), Color(line, 0.8), 1.5, true)
			2:  # rivets: a stud on each corner and a cap along the edge
				var p := origin + Vector2(sx, sy) * 11.0
				c.draw_circle(p, 5.5, Color(0.1, 0.08, 0.05))
				c.draw_circle(p, 4.0, line)
				c.draw_circle(p + Vector2(-1, -1), 1.6, Color(1, 1, 1, 0.6))
				c.draw_line(p + Vector2(sx * 12.0, 0), p + Vector2(sx * (s + 6.0), 0), Color(line, 0.7), 2.0, true)
				c.draw_line(p + Vector2(0, sy * 12.0), p + Vector2(0, sy * (s + 6.0)), Color(line, 0.7), 2.0, true)
	# Top center ornament.
	match style:
		0:
			_diamond(c, Vector2(r.size.x * 0.5, 0.0), 6.0, line)
			c.draw_line(Vector2(r.size.x * 0.5 - 40.0, 0.0), Vector2(r.size.x * 0.5 - 9.0, 0.0), line, 3.0)
			c.draw_line(Vector2(r.size.x * 0.5 + 9.0, 0.0), Vector2(r.size.x * 0.5 + 40.0, 0.0), line, 3.0)
		1:
			c.draw_polygon(PackedVector2Array([Vector2(r.size.x * 0.5 - 22.0, 0.0), Vector2(r.size.x * 0.5, 7.0),
				Vector2(r.size.x * 0.5 + 22.0, 0.0)]), PackedColorArray([line, line, line]))
		2:
			c.draw_circle(Vector2(r.size.x * 0.5, 0.0), 6.0, line)
			c.draw_circle(Vector2(r.size.x * 0.5, 0.0), 2.5, Color(0.1, 0.08, 0.05))


## Title with a rule and a diamond underneath.
func _heading(text: String, rect: Rect2, size: int) -> void:
	_label(text, size, _t["text"], rect.position, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, true, 0)
	var y := rect.position.y + size * 1.3
	_canvas(Rect2(rect.position.x, y, rect.size.x, 14), func(c: Control) -> void:
		var mid := c.size.x * 0.5
		var line: Color = _t["line"]
		c.draw_line(Vector2(mid - 150, 7), Vector2(mid - 14, 7), line, 2.0)
		c.draw_line(Vector2(mid + 14, 7), Vector2(mid + 150, 7), line, 2.0)
		_diamond(c, Vector2(mid, 7), 6.0, line))


## Pill-like button with a gradient and ornament ends.
func _button(rect: Rect2, text: String, selected: bool, size: int = 30) -> void:
	_canvas(rect, func(c: Control) -> void:
		var line: Color = _t["line"]
		var fill: Color = _t["cta1"] if selected else _t["panel2"]
		var pts := _outline_points(Rect2(Vector2.ZERO, c.size), _t["style"], 0.0)
		c.draw_colored_polygon(pts, Color(fill, 0.95 if selected else 0.8))
		if selected:
			c.draw_polyline(_close(pts), Color(line, 0.3), 8.0, true)
			var shine := PackedColorArray([Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])
			c.draw_polygon(PackedVector2Array([Vector2(8, 3), Vector2(c.size.x - 8, 3), Vector2(c.size.x - 8, c.size.y * 0.5),
				Vector2(8, c.size.y * 0.5)]), shine)
		c.draw_polyline(_close(pts), Color(line, 0.95 if selected else 0.45), 2.0, true)
		_diamond(c, Vector2(22, c.size.y * 0.5), 6.0, line if selected else Color(line, 0.55)))
	_label(text, size, _t["text"] if selected else _t["muted"], rect.position + Vector2(52, rect.size.y * 0.5 - size * 0.78),
		0.0, HORIZONTAL_ALIGNMENT_LEFT, false)


func _coin(at: Vector2, size: float) -> void:
	var rect := Rect2(at - Vector2(size, size) * 0.5, Vector2(size, size))
	_tex("res://assets/icons/ui/coin.svg", rect)


func _icon_tile(path: String, rect: Rect2) -> void:
	_canvas(rect, func(c: Control) -> void:
		var line: Color = _t["line"]
		var pts := _outline_points(Rect2(Vector2.ZERO, c.size), _t["style"], 0.0)
		c.draw_colored_polygon(pts, Color(_t["bg1"], 0.9))
		c.draw_polyline(_close(pts), Color(line, 0.8), 2.0, true))
	if path != "":
		_tex(path, Rect2(rect.position + Vector2(8, 8), rect.size - Vector2(16, 16)))


# --- Sheet ------------------------------------------------------------------------

func _build() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(W, H)
	bg.color = _t["bg1"]
	_root.add_child(bg)
	_canvas(Rect2(0, 0, W, H), func(c: Control) -> void:
		var top: Color = _t["bg2"]
		var colors := PackedColorArray([Color(top, 0.0), Color(top, 0.0), top, top])
		c.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]), colors)
		# Soft vignette glow behind the right panels.
		for k in 6:
			c.draw_circle(Vector2(W * 0.74, H * 0.45), 700.0 - k * 90.0, Color(_t["line2"], 0.035)))
	_menu()
	_shop()
	_level_up()
	_hud()
	_header()


func _header() -> void:
	_label(_t["name"], 34, _t["text"], Vector2(40, 8), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(_t["tag"], 18, _t["muted"], Vector2(44, 52))


func _menu() -> void:
	var panel := Rect2(40, 90, 780, 760)
	_frame(panel, Color(_t["panel"], 0.92))
	_tex("res://assets/ui/menu_boss.png", Rect2(450, 330, 360, 500))
	_label("SURVIVOR", 96, _t["text"], Vector2(70, 110), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true, 8)
	_canvas(Rect2(76, 262, 400, 14), func(c: Control) -> void:
		c.draw_line(Vector2(0, 7), Vector2(170, 7), _t["line"], 3.0)
		_diamond(c, Vector2(186, 7), 7.0, _t["line"])
		c.draw_line(Vector2(202, 7), Vector2(400, 7), Color(_t["line"], 0.5), 2.0))
	for i in MENU.size():
		_button(Rect2(70, 300 + i * 86, 380, 72), MENU[i], i == 0)


func _shop() -> void:
	var panel := Rect2(860, 90, 1020, 470)
	_frame(panel, Color(_t["panel"], 0.94))
	_label("BOUTIQUE — VAGUE 1", 40, _t["text"], Vector2(900, 112), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label("43", 40, _t["price"], Vector2(1760, 110), 70, HORIZONTAL_ALIGNMENT_RIGHT)
	_coin(Vector2(1850, 134), 40.0)
	for i in OFFERS.size():
		var card := Rect2(890 + i * 245, 180, 230, 350)
		_frame(card, Color(_t["panel2"], 0.95), i == 0, 0.8)
		var item_id: String = OFFERS[i][0]
		var icon := "res://assets/icons/weapons/katana.png" if item_id == "" else "res://assets/icons/items/%s.png" % item_id
		_icon_tile(icon, Rect2(card.position + Vector2(65, 26), Vector2(100, 100)))
		_label(OFFERS[i][1], 25, _t["text"], card.position + Vector2(10, 140), 210, HORIZONTAL_ALIGNMENT_CENTER, true)
		_label(OFFERS[i][2], 17, _t["muted"], card.position + Vector2(14, 218), 202, HORIZONTAL_ALIGNMENT_CENTER)
		_button(Rect2(card.position + Vector2(24, 284), Vector2(182, 46)), "", i == 0, 20)
		_label(str(OFFERS[i][3]), 26, _t["price"], card.position + Vector2(90, 288), 50, HORIZONTAL_ALIGNMENT_CENTER)
		_coin(card.position + Vector2(150, 307), 26.0)


func _level_up() -> void:
	var panel := Rect2(860, 580, 1020, 290)
	_frame(panel, Color(_t["panel"], 0.94))
	_label("NIVEAU SUPÉRIEUR !", 36, _t["accent"], Vector2(860, 590), 1020, HORIZONTAL_ALIGNMENT_CENTER, true)
	for i in UPGRADES.size():
		var card := Rect2(890 + i * 245, 650, 230, 200)
		_frame(card, Color(_t["panel2"], 0.95), i == 0, 0.8)
		_icon_tile("res://assets/icons/items/%s.png" % UPGRADES[i][0], Rect2(card.position + Vector2(80, 14), Vector2(70, 70)))
		_label(UPGRADES[i][1], 26, _t["text"], card.position + Vector2(10, 90), 210, HORIZONTAL_ALIGNMENT_CENTER, true)
		_label(UPGRADES[i][2], 17, _t["muted"], card.position + Vector2(14, 146), 202, HORIZONTAL_ALIGNMENT_CENTER)


func _hud() -> void:
	var bar := Rect2(40, 890, 1840, 150)
	_frame(bar, Color(_t["panel"], 0.95))
	_icon_tile("", Rect2(66, 912, 106, 106))
	var hero := ContentDB.get_def(&"characters", &"drifter") as CharacterData
	var art := hero.card_art
	var atlas := AtlasTexture.new()
	atlas.atlas = art
	atlas.region = CharacterSelect.head_region(art)
	var face := TextureRect.new()
	face.texture = atlas
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.position = Vector2(70, 916)
	face.size = Vector2(98, 98)
	_root.add_child(face)
	_label("Niv. 3 (+2)", 22, _t["muted"], Vector2(196, 906))
	_canvas(Rect2(196, 940, 760, 40), func(c: Control) -> void:
		var pts := _outline_points(Rect2(Vector2.ZERO, c.size), _t["style"], 0.0)
		c.draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
		c.draw_colored_polygon(_outline_points(Rect2(3, 3, c.size.x * 0.82 - 6.0, c.size.y - 6.0), _t["style"], 0.0), _t["accent"])
		c.draw_polyline(_close(pts), Color(_t["line"], 0.9), 2.0, true))
	_label("100 / 100", 22, Color.WHITE, Vector2(196, 945), 760, HORIZONTAL_ALIGNMENT_CENTER, false, 4)
	_label("XP", 16, _t["muted"], Vector2(196, 990))
	_canvas(Rect2(196, 1010, 760, 12), func(c: Control) -> void:
		c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0, 0, 0, 0.55))
		c.draw_rect(Rect2(Vector2.ZERO, Vector2(c.size.x * 0.4, c.size.y)), Color(_t["line"], 0.9))
		c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(_t["line"], 0.5), false, 1.5))
	for k in 4:
		_icon_tile("res://assets/icons/weapons/katana.png" if k < 3 else "", Rect2(1010 + k * 120, 906, 106, 106))
	_canvas(Rect2(1600, 900, 120, 120), func(c: Control) -> void:
		c.draw_circle(c.size * 0.5, 54.0, Color(_t["bg1"], 0.9))
		c.draw_arc(c.size * 0.5, 54.0, 0.0, TAU, 48, _t["line"], 3.0, true)
		c.draw_arc(c.size * 0.5, 44.0, 0.0, TAU, 48, Color(_t["line2"], 0.9), 1.5, true))
	_label("12", 48, _t["text"], Vector2(1600, 916), 120, HORIZONTAL_ALIGNMENT_CENTER, true)
	_label("VAGUE", 15, _t["muted"], Vector2(1600, 972), 120, HORIZONTAL_ALIGNMENT_CENTER)
