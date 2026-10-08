extends Node
## Debug tool: proposals for a full UI re-theme (ornaments, palette, typography). Each
## theme is drawn on two 1920x1080 sheets built from the real game art and data:
## sheet "run" = main menu, shop, level-up, HUD; sheet "meta" = hunter select, seals, victory,
## skin shop, progression, pause and settings. Throwaway (nothing here is used by the game):
## the dev picks one, then the real theme (UiTheme) is rebuilt on it.
## Fonts are read at runtime from art_tests/ui_themes/fonts (OFL, not in the project yet).
## Usage: Godot.exe --path . res://src/debug/theme_mockup.tscn -- --theme=1..5 --sheet=run|meta --out=<png>

const W := 1920.0
const H := 1080.0
const FONT_DIR := "res://art_tests/ui_themes/fonts/"

## Frame styles: 0 gothic, 1 arcane chamfer, 2 rivets, 3 filigree, 4 tech, 5 plaque, 6 organic.
const THEMES := {
	"1": {
		"name": "VOILE D'AMÉTHYSTE", "tag": "Violet arcanique · lilas · argent · filigranes",
		"bg1": Color("0d0718"), "bg2": Color("2a1450"), "panel": Color("1b1230"), "panel2": Color("2b1d4a"),
		"line": Color("c9a8ff"), "line2": Color("6a3fc0"), "text": Color("f0e8ff"), "muted": Color("a893d6"),
		"accent": Color("d278ff"), "price": Color("ffd98a"), "cta1": Color("8a4dff"), "cta2": Color("4a22a8"),
		"title": "Almendra-Bold.ttf", "body": "CrimsonPro.ttf", "style": 3, "weight": 600, "alpha": 0.93,
	},
	"2": {
		"name": "CRISTAL D'AZUR", "tag": "Holographique · bleu nuit · cyan · accent corail",
		"bg1": Color("050a1c"), "bg2": Color("0e2a66"), "panel": Color("0a1636"), "panel2": Color("12285a"),
		"line": Color("5cc8ff"), "line2": Color("2a5fd0"), "text": Color("e8f4ff"), "muted": Color("84a8d8"),
		"accent": Color("4fe3ff"), "price": Color("ffb36b"), "cta1": Color("2f7bff"), "cta2": Color("163a99"),
		"title": "Orbitron.ttf", "body": "Exo2.ttf", "style": 4, "weight": 600, "alpha": 0.9,
	},
	"3": {
		"name": "AUBE DORÉE", "tag": "Parchemin clair · or · turquoise · façon gacha",
		"bg1": Color("e9dcc3"), "bg2": Color("c7a96d"), "panel": Color("f6efe0"), "panel2": Color("fffaf0"),
		"line": Color("b8893a"), "line2": Color("d9c08a"), "text": Color("3a2c1a"), "muted": Color("8a7655"),
		"accent": Color("2a9d8f"), "price": Color("b8651b"), "cta1": Color("e0a93b"), "cta2": Color("a8721a"),
		"title": "Cinzel.ttf", "body": "Marcellus-Regular.ttf", "style": 5, "weight": 600, "alpha": 0.97,
	},
	"4": {
		"name": "FORÊT D'ÉMERAUDE", "tag": "Vert profond · bronze · runes · motifs végétaux",
		"bg1": Color("06100c"), "bg2": Color("15402c"), "panel": Color("0e1e17"), "panel2": Color("173226"),
		"line": Color("c89b5a"), "line2": Color("3f7a54"), "text": Color("eaf2e0"), "muted": Color("8fae98"),
		"accent": Color("7be0a0"), "price": Color("f0c36a"), "cta1": Color("2f9a62"), "cta2": Color("17603a"),
		"title": "UncialAntiqua-Regular.ttf", "body": "Eczar.ttf", "style": 6, "weight": 500, "alpha": 0.93,
	},
	"5": {
		"name": "BRAISE", "tag": "Noir volcanique · orange magma · acier forgé",
		"bg1": Color("0a0706"), "bg2": Color("3a1206"), "panel": Color("16100e"), "panel2": Color("261a16"),
		"line": Color("ff8a2a"), "line2": Color("6a3a1e"), "text": Color("f7ece2"), "muted": Color("b09a88"),
		"accent": Color("ff5a1f"), "price": Color("ffd24a"), "cta1": Color("e0561a"), "cta2": Color("8a2a0a"),
		"title": "Rajdhani-Bold.ttf", "body": "Rajdhani-Bold.ttf", "style": 2, "weight": 600, "alpha": 0.94,
	},
}

const MENU := ["Jouer", "Coop locale", "Progression", "Boutique de skins", "Paramètres", "Quitter"]
const OFFERS := [["rage_potion", "Potion de régénération", "+1 Régénération", 12],
	["swift_rune", "Rune de célérité", "+6 % Vitesse d'attaque", 18],
	["", "Épée flamboyante", "Enflamme les ennemis", 20],
	["magnet_glove", "Gant de magnétite", "+40 Portée de ramassage", 10]]
const UPGRADES := [["magnet_glove", "Aimant", "+22 % Portée de ramassage"], ["swift_rune", "Frénésie", "+8 % Vitesse d'attaque"],
	["tracker_boots", "Esquive", "+5 % Esquive"], ["hunter_mark", "Précision", "+5 % Chance de critique"]]
const HEROES := ["drifter", "assassin", "berserker", "gunslinger", "mage", "merchant"]
const HERO_NAMES := ["Chasseuse novice", "Assassin", "Berserkeuse", "Archère", "Mage", "Contrebandière"]
const SEAL_COLORS: Array[Color] = [Color("d9874a"), Color("b8c0cc"), Color("eef2f8"), Color("ffd84d"), Color("b86bff"), Color("8fe9ff")]

var _t: Dictionary
var _root: Control
var _fonts: Dictionary = {}
var _out := "user://theme_mockup.png"


func _ready() -> void:
	var which := "1"
	var sheet := "run"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--theme="):
			which = arg.trim_prefix("--theme=")
		elif arg.begins_with("--sheet="):
			sheet = arg.trim_prefix("--sheet=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_t = THEMES[which]
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(1920, 1080)
	get_window().position = Vector2i(0, 0)
	_root = Control.new()
	_root.size = Vector2(W, H)
	add_child(_root)
	_background()
	if sheet == "run":
		_menu()
		_shop()
		_level_up()
		_hud()
	else:
		_select(Rect2(30, 50, 620, 500))
		_seals(Rect2(650, 50, 620, 500))
		_victory(Rect2(1270, 50, 620, 500))
		_skin_shop(Rect2(30, 560, 620, 500))
		_progression(Rect2(650, 560, 620, 500))
		_pause_settings(Rect2(1270, 560, 620, 500))
	_label("%s  —  %s" % [_t["name"], "RUN" if sheet == "run" else "MÉTA"], 28, _t["text"], Vector2(40, 2), 0.0,
		HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(_t["tag"], 16, _t["muted"], Vector2(820, 10))
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	print("theme mockup saved: ", _out)
	get_tree().quit()


# --- Helpers ------------------------------------------------------------------

func _light() -> bool:
	return (_t["bg1"] as Color).get_luminance() > 0.5


func _font(key: String) -> Font:
	var file: String = _t[key]
	if not _fonts.has(file):
		var font := FontFile.new()
		font.load_dynamic_font(ProjectSettings.globalize_path(FONT_DIR + file))
		_fonts[file] = font
	var f: Font = _fonts[file]
	if key == "body" and file in ["CrimsonPro.ttf", "Exo2.ttf", "Eczar.ttf", "SourceSerif4.ttf"]:
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
	var node := TextureRect.new()
	var texture: Texture2D = load(path)
	if region.size != Vector2.ZERO:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = region
		texture = atlas
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.position = rect.position
	node.size = rect.size
	_root.add_child(node)


func _head(hero: String, rect: Rect2) -> void:
	var art: Texture2D = load("res://assets/characters/cards/%s_card.png" % hero)
	var atlas := AtlasTexture.new()
	atlas.atlas = art
	atlas.region = CharacterSelect.head_region(art)
	var node := TextureRect.new()
	node.texture = atlas
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.position = rect.position
	node.size = rect.size
	_root.add_child(node)


func _canvas(rect: Rect2, painter: Callable) -> Control:
	var c := Control.new()
	c.position = rect.position
	c.size = rect.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(painter.bind(c))
	_root.add_child(c)
	return c


func _background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(W, H)
	bg.color = _t["bg1"]
	_root.add_child(bg)
	_canvas(Rect2(0, 0, W, H), func(c: Control) -> void:
		var top: Color = _t["bg2"]
		c.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
			PackedColorArray([Color(top, 0.0), Color(top, 0.0), top, top]))
		for k in 7:
			c.draw_circle(Vector2(W * 0.5, H * 0.5), 820.0 - k * 100.0, Color(_t["line2"], 0.03))
		for k in 3:
			c.draw_arc(Vector2(W * 0.5, H * 0.5), 360.0 + k * 90.0, 0.0, TAU, 96, Color(_t["line"], 0.05), 2.0, true))


# --- Shapes and ornaments ----------------------------------------------------------

## Corner radius or cut of a style's outline.
func _corner(style: int) -> float:
	match style:
		0:
			return 4.0
		1:
			return 14.0
		2:
			return 8.0
		3:
			return 20.0
		4:
			return 12.0
		5:
			return 14.0
		6:
			return 24.0
	return 8.0


## Outline polygon of a style: cut corners (0, 1, 2), asymmetric cuts (4), rounded (3, 5, 6).
func _shape(r: Rect2, style: int) -> PackedVector2Array:
	var k := minf(_corner(style), minf(r.size.x, r.size.y) * 0.45)
	var pts := PackedVector2Array()
	match style:
		3, 5, 6:
			var corners := [[r.position + Vector2(k, k), PI], [r.position + Vector2(r.size.x - k, k), PI * 1.5],
				[r.position + Vector2(r.size.x - k, r.size.y - k), 0.0], [r.position + Vector2(k, r.size.y - k), PI * 0.5]]
			for corner in corners:
				for s in 7:
					var a: float = corner[1] + (PI * 0.5) * s / 6.0
					pts.append(corner[0] + Vector2.from_angle(a) * k)
		4:
			var big := minf(k * 2.4, minf(r.size.x, r.size.y) * 0.4)
			pts = PackedVector2Array([r.position + Vector2(big, 0), r.position + Vector2(r.size.x, 0),
				r.position + Vector2(r.size.x, r.size.y - big), r.position + Vector2(r.size.x - big, r.size.y),
				r.position + Vector2(0, r.size.y), r.position + Vector2(0, big)])
		_:
			pts = PackedVector2Array([r.position + Vector2(k, 0), r.position + Vector2(r.size.x - k, 0),
				r.position + Vector2(r.size.x, k), r.position + Vector2(r.size.x, r.size.y - k),
				r.position + Vector2(r.size.x - k, r.size.y), r.position + Vector2(k, r.size.y),
				r.position + Vector2(0, r.size.y - k), r.position + Vector2(0, k)])
	return pts


func _close(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out


func _diamond(c: Control, at: Vector2, size: float, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -size), at + Vector2(size, 0), at + Vector2(0, size),
		at + Vector2(-size, 0)]), color)


func _frame(rect: Rect2, fill: Color, glow: bool = false, emphasis: float = 1.0) -> void:
	_canvas(rect, func(c: Control) -> void: _paint_frame(c, fill, glow, emphasis))


func _paint_frame(c: Control, fill: Color, glow: bool, emphasis: float) -> void:
	var r := Rect2(Vector2.ZERO, c.size)
	var line: Color = _t["line"]
	var line2: Color = _t["line2"]
	var style: int = _t["style"]
	var pts := _shape(r, style)
	var inner := _shape(r.grow(-7.0), style)
	c.draw_colored_polygon(pts, fill)
	c.draw_polygon(PackedVector2Array([r.position + Vector2(10, 8), r.position + Vector2(r.size.x - 10, 8),
		r.position + Vector2(r.size.x - 10, r.size.y * 0.45), r.position + Vector2(10, r.size.y * 0.45)]),
		PackedColorArray([Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)]))
	if glow:
		c.draw_polyline(_close(pts), Color(line, 0.28), 10.0 * emphasis, true)
	c.draw_polyline(_close(pts), Color(line, 0.95), (3.5 if style == 5 else 2.5) * emphasis, true)
	c.draw_polyline(_close(inner), Color(line2, 0.9), 1.5, true)
	_corners(c, r, style, line, emphasis)


func _corners(c: Control, r: Rect2, style: int, line: Color, emphasis: float) -> void:
	var s := minf(34.0, minf(r.size.x, r.size.y) * 0.25) * emphasis
	for corner in 4:
		var sx := -1.0 if corner % 2 == 1 else 1.0
		var sy := -1.0 if corner >= 2 else 1.0
		var origin := r.position + Vector2(0.0 if sx > 0 else r.size.x, 0.0 if sy > 0 else r.size.y)
		match style:
			0:
				var p := origin + Vector2(sx, sy) * 5.0
				c.draw_polyline(PackedVector2Array([p + Vector2(sx * s, 0), p, p + Vector2(0, sy * s)]), line, 3.0, true)
				_diamond(c, p + Vector2(sx * s, 0), 3.5, line)
				_diamond(c, p + Vector2(0, sy * s), 3.5, line)
				_diamond(c, p, 4.5, line)
			1:
				var p := origin + Vector2(sx, sy) * 11.0
				c.draw_circle(p, 6.0 * emphasis, Color(line, 0.25))
				c.draw_circle(p, 3.0, line)
				c.draw_line(p + Vector2(sx * 8.0, 0), p + Vector2(sx * s, 0), Color(line, 0.8), 1.5, true)
				c.draw_line(p + Vector2(0, sy * 8.0), p + Vector2(0, sy * s), Color(line, 0.8), 1.5, true)
			2:
				var p := origin + Vector2(sx, sy) * 11.0
				c.draw_circle(p, 5.5, Color(0.1, 0.08, 0.05))
				c.draw_circle(p, 4.0, line)
				c.draw_circle(p + Vector2(-1, -1), 1.6, Color(1, 1, 1, 0.6))
				c.draw_line(p + Vector2(sx * 12.0, 0), p + Vector2(sx * (s + 6.0), 0), Color(line, 0.7), 2.0, true)
				c.draw_line(p + Vector2(0, sy * 12.0), p + Vector2(0, sy * (s + 6.0)), Color(line, 0.7), 2.0, true)
			3:
				var p := origin + Vector2(sx, sy) * 16.0
				var curl := PackedVector2Array()
				for k in 14:
					var a := float(k) / 13.0 * PI * 1.5
					var rad := 3.0 + 12.0 * (1.0 - float(k) / 13.0)
					curl.append(p + Vector2(cos(a) * sx, sin(a) * sy) * rad + Vector2(sx * 4.0, sy * 4.0))
				c.draw_polyline(curl, line, 2.2, true)
				c.draw_circle(p + Vector2(sx, sy) * 7.0, 2.6, line)
			4:
				var p := origin + Vector2(sx, sy) * 6.0
				if (sx > 0.0) == (sy > 0.0):
					c.draw_polyline(PackedVector2Array([p + Vector2(sx * s * 1.4, 0), p, p + Vector2(0, sy * s * 1.4)]), line, 2.5, true)
				else:
					c.draw_circle(p + Vector2(sx, sy) * 6.0, 3.0, line)
					c.draw_line(p + Vector2(sx * 12.0, sy * 6.0), p + Vector2(sx * 40.0, sy * 6.0), Color(line, 0.7), 1.5, true)
			5:
				var p := origin + Vector2(sx, sy) * 12.0
				for d in [Vector2(5, 0), Vector2(-5, 0), Vector2(0, 5), Vector2(0, -5)]:
					c.draw_circle(p + d, 3.4, line)
				c.draw_circle(p, 3.0, _t["panel2"])
			6:
				var p := origin + Vector2(sx, sy) * 14.0
				c.draw_arc(p + Vector2(sx, sy) * 4.0, 13.0, 0.0, TAU * 0.78, 18, line, 2.4, true)
				var leaf := PackedVector2Array([p + Vector2(sx * 16.0, sy * 2.0), p + Vector2(sx * 30.0, sy * 6.0),
					p + Vector2(sx * 18.0, sy * 14.0)])
				c.draw_colored_polygon(leaf, Color(_t["accent"], 0.9))
	var m := r.size.x * 0.5
	match style:
		0:
			_diamond(c, Vector2(m, 0.0), 6.0, line)
			c.draw_line(Vector2(m - 40.0, 0.0), Vector2(m - 9.0, 0.0), line, 3.0)
			c.draw_line(Vector2(m + 9.0, 0.0), Vector2(m + 40.0, 0.0), line, 3.0)
		1:
			c.draw_colored_polygon(PackedVector2Array([Vector2(m - 22.0, 0.0), Vector2(m, 7.0), Vector2(m + 22.0, 0.0)]), line)
		2:
			c.draw_circle(Vector2(m, 0.0), 6.0, line)
			c.draw_circle(Vector2(m, 0.0), 2.5, Color(0.1, 0.08, 0.05))
		3:
			c.draw_colored_polygon(PackedVector2Array([Vector2(m, -9), Vector2(m + 8, 0), Vector2(m, 9), Vector2(m - 8, 0)]), _t["accent"])
			c.draw_polyline(PackedVector2Array([Vector2(m, -9), Vector2(m + 8, 0), Vector2(m, 9), Vector2(m - 8, 0), Vector2(m, -9)]), line, 2.0)
			c.draw_line(Vector2(m + 12, 0), Vector2(m + 60, 0), line, 2.0)
			c.draw_line(Vector2(m - 12, 0), Vector2(m - 60, 0), line, 2.0)
		4:
			for k in 6:
				c.draw_line(Vector2(m - 50.0 + k * 20.0, 0.0), Vector2(m - 40.0 + k * 20.0, 6.0), Color(line, 0.8), 2.0)
		5:
			c.draw_circle(Vector2(m, 0.0), 9.0, line)
			c.draw_circle(Vector2(m, 0.0), 5.0, _t["accent"])
		6:
			c.draw_colored_polygon(PackedVector2Array([Vector2(m - 14, 2), Vector2(m, -10), Vector2(m + 14, 2), Vector2(m, 8)]), _t["accent"])
			c.draw_line(Vector2(m + 18, 0), Vector2(m + 70, 0), line, 2.0)
			c.draw_line(Vector2(m - 18, 0), Vector2(m - 70, 0), line, 2.0)


func _button(rect: Rect2, text: String, selected: bool, size: int = 28, center: bool = false) -> void:
	_canvas(rect, func(c: Control) -> void:
		var line: Color = _t["line"]
		var fill: Color = _t["cta1"] if selected else _t["panel2"]
		var pts := _shape(Rect2(Vector2.ZERO, c.size), _t["style"])
		c.draw_colored_polygon(pts, Color(fill, 0.97 if selected else 0.85))
		if selected:
			c.draw_polyline(_close(pts), Color(line, 0.3), 8.0, true)
			c.draw_polygon(PackedVector2Array([Vector2(8, 3), Vector2(c.size.x - 8, 3), Vector2(c.size.x - 8, c.size.y * 0.5),
				Vector2(8, c.size.y * 0.5)]), PackedColorArray([Color(1, 1, 1, 0.2), Color(1, 1, 1, 0.2), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)]))
		c.draw_polyline(_close(pts), Color(line, 0.95 if selected else 0.5), 2.0, true)
		if not center:
			_diamond(c, Vector2(22, c.size.y * 0.5), 6.0, line if selected else Color(line, 0.55)))
	var color: Color = Color.WHITE if selected else _t["text"]
	if text != "":
		var w := rect.size.x if center else 0.0
		_label(text, size, color, rect.position + Vector2(0.0 if center else 52.0, rect.size.y * 0.5 - size * 0.78), w,
			HORIZONTAL_ALIGNMENT_CENTER, false)


func _coin(at: Vector2, size: float) -> void:
	_tex("res://assets/icons/ui/coin.svg", Rect2(at - Vector2(size, size) * 0.5, Vector2(size, size)))


func _shard(at: Vector2, size: float) -> void:
	_tex("res://assets/icons/ui/shard.png", Rect2(at - Vector2(size, size) * 0.5, Vector2(size, size)))


func _icon_tile(path: String, rect: Rect2) -> void:
	_canvas(rect, func(c: Control) -> void:
		var pts := _shape(Rect2(Vector2.ZERO, c.size), _t["style"])
		c.draw_colored_polygon(pts, Color(_t["bg1"], 0.9) if not _light() else Color(1, 1, 1, 0.7))
		c.draw_polyline(_close(pts), Color(_t["line"], 0.8), 2.0, true))
	if path != "":
		_tex(path, Rect2(rect.position + Vector2(8, 8), rect.size - Vector2(16, 16)))


func _bar(rect: Rect2, share: float, color: Color) -> void:
	_canvas(rect, func(c: Control) -> void:
		var pts := _shape(Rect2(Vector2.ZERO, c.size), 1)
		c.draw_colored_polygon(pts, Color(0, 0, 0, 0.45) if not _light() else Color(0, 0, 0, 0.18))
		c.draw_colored_polygon(_shape(Rect2(3, 3, maxf(c.size.x * share - 6.0, 4.0), c.size.y - 6.0), 1), color)
		c.draw_polyline(_close(pts), Color(_t["line"], 0.9), 2.0, true))


func _tab(rect: Rect2, text: String, active: bool) -> void:
	_button(rect, text, active, 20, true)


# --- Sheet "run" -----------------------------------------------------------------------

func _menu() -> void:
	_frame(Rect2(40, 60, 780, 790), Color(_t["panel"], _t["alpha"]))
	_tex("res://assets/ui/menu_boss.png", Rect2(450, 330, 360, 500))
	_label("SURVIVOR", 96, _t["text"], Vector2(70, 80), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true, 6 if not _light() else 0)
	_canvas(Rect2(76, 240, 400, 14), func(c: Control) -> void:
		c.draw_line(Vector2(0, 7), Vector2(170, 7), _t["line"], 3.0)
		_diamond(c, Vector2(186, 7), 7.0, _t["line"])
		c.draw_line(Vector2(202, 7), Vector2(400, 7), Color(_t["line"], 0.5), 2.0))
	for i in MENU.size():
		_button(Rect2(70, 280 + i * 90, 380, 72), MENU[i], i == 0)


func _shop() -> void:
	_frame(Rect2(860, 60, 1020, 490), Color(_t["panel"], _t["alpha"]))
	_label("BOUTIQUE — VAGUE 1", 38, _t["text"], Vector2(900, 82), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label("43", 38, _t["price"], Vector2(1760, 82), 70, HORIZONTAL_ALIGNMENT_RIGHT)
	_coin(Vector2(1850, 106), 40.0)
	for i in OFFERS.size():
		var card := Rect2(890 + i * 245, 160, 230, 370)
		_frame(card, Color(_t["panel2"], 0.97), i == 0, 0.8)
		var item_id: String = OFFERS[i][0]
		var icon := "res://assets/icons/weapons/katana.png" if item_id == "" else "res://assets/icons/items/%s.png" % item_id
		_icon_tile(icon, Rect2(card.position + Vector2(65, 26), Vector2(100, 100)))
		_label(OFFERS[i][1], 24, _t["text"], card.position + Vector2(10, 138), 210, HORIZONTAL_ALIGNMENT_CENTER, true)
		_label(OFFERS[i][2], 17, _t["muted"], card.position + Vector2(14, 222), 202, HORIZONTAL_ALIGNMENT_CENTER)
		_button(Rect2(card.position + Vector2(24, 304), Vector2(182, 46)), "", i == 0, 20)
		_label(str(OFFERS[i][3]), 26, Color.WHITE if i == 0 else _t["price"], card.position + Vector2(90, 309), 50, HORIZONTAL_ALIGNMENT_CENTER)
		_coin(card.position + Vector2(150, 327), 26.0)


func _level_up() -> void:
	_frame(Rect2(860, 570, 1020, 290), Color(_t["panel"], _t["alpha"]))
	_label("NIVEAU SUPÉRIEUR !", 36, _t["accent"], Vector2(860, 580), 1020, HORIZONTAL_ALIGNMENT_CENTER, true)
	for i in UPGRADES.size():
		var card := Rect2(890 + i * 245, 646, 230, 200)
		_frame(card, Color(_t["panel2"], 0.97), i == 0, 0.8)
		_icon_tile("res://assets/icons/items/%s.png" % UPGRADES[i][0], Rect2(card.position + Vector2(80, 14), Vector2(70, 70)))
		_label(UPGRADES[i][1], 26, _t["text"], card.position + Vector2(10, 92), 210, HORIZONTAL_ALIGNMENT_CENTER, true)
		_label(UPGRADES[i][2], 17, _t["muted"], card.position + Vector2(14, 144), 202, HORIZONTAL_ALIGNMENT_CENTER)


func _hud() -> void:
	_frame(Rect2(40, 890, 1840, 150), Color(_t["panel"], _t["alpha"]))
	_icon_tile("", Rect2(66, 912, 106, 106))
	_head("drifter", Rect2(70, 916, 98, 98))
	_label("Niv. 3 (+2)", 22, _t["muted"], Vector2(196, 904))
	_bar(Rect2(196, 940, 760, 40), 0.82, _t["accent"])
	_label("100 / 100", 22, Color.WHITE, Vector2(196, 945), 760, HORIZONTAL_ALIGNMENT_CENTER, false, 4)
	_label("XP", 16, _t["muted"], Vector2(196, 988))
	_bar(Rect2(196, 1010, 760, 14), 0.4, _t["line"])
	for k in 4:
		_icon_tile("res://assets/icons/weapons/katana.png" if k < 3 else "", Rect2(1010 + k * 120, 906, 106, 106))
	_canvas(Rect2(1600, 900, 120, 120), func(c: Control) -> void:
		c.draw_circle(c.size * 0.5, 54.0, Color(_t["bg1"], 0.9))
		c.draw_arc(c.size * 0.5, 54.0, 0.0, TAU, 48, _t["line"], 3.0, true)
		c.draw_arc(c.size * 0.5, 44.0, 0.0, TAU, 48, Color(_t["line2"], 0.9), 1.5, true))
	_label("12", 48, _t["text"], Vector2(1600, 916), 120, HORIZONTAL_ALIGNMENT_CENTER, true)
	_label("VAGUE", 15, _t["muted"], Vector2(1600, 972), 120, HORIZONTAL_ALIGNMENT_CENTER)


# --- Sheet "meta": each screen draws inside a cell ------------------------------------------

func _cell(r: Rect2, title: String) -> void:
	var inner := r.grow(-8.0)
	_frame(inner, Color(_t["panel"], _t["alpha"]))
	_label(title, 28, _t["text"], inner.position + Vector2(0, 14), inner.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)


func _select(r: Rect2) -> void:
	_cell(r, "CHOISIS TON CHASSEUR")
	var o := r.position
	for i in 4:
		var row := Rect2(o + Vector2(24, 72 + i * 92), Vector2(150, 84))
		_frame(row, Color(_t["panel2"], 0.97), i == 0, 0.5)
		_head(HEROES[i], Rect2(row.position + Vector2(6, 6), Vector2(64, 64)))
		_label(HERO_NAMES[i], 14, _t["text"], row.position + Vector2(72, 28), 76)
	_canvas(Rect2(o + Vector2(190, 380), Vector2(220, 60)), func(c: Control) -> void:
		c.draw_circle(Vector2(110, 6), 70.0, Color(_t["line2"], 0.18))
		c.draw_arc(Vector2(110, 6), 66.0, PI * 0.1, PI * 0.9, 24, Color(_t["line"], 0.8), 3.0, true))
	_tex("res://assets/characters/cards/drifter_card.png", Rect2(o + Vector2(190, 66), Vector2(220, 330)))
	_label("Chasseuse novice", 22, _t["text"], o + Vector2(190, 406), 220, HORIZONTAL_ALIGNMENT_CENTER, true)
	_label("Éveil : cartes d'amélioration +50 %", 14, _t["muted"], o + Vector2(190, 440), 220, HORIZONTAL_ALIGNMENT_CENTER)
	_label("ARMES", 20, _t["accent"], o + Vector2(440, 72), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_button(Rect2(o + Vector2(430, 106), Vector2(160, 60)), "Épée", true, 18, true)
	_button(Rect2(o + Vector2(430, 176), Vector2(160, 60)), "Orbe", false, 18, true)
	_button(Rect2(o + Vector2(430, 400), Vector2(160, 54)), "Suivant", true, 20, true)


func _seals(r: Rect2) -> void:
	_cell(r, "CHOISIS TON SCEAU")
	var o := r.position
	for i in 6:
		var at := o + Vector2(62 + i * 99, 130)
		var locked := i > 2
		_canvas(Rect2(at - Vector2(40, 40), Vector2(80, 80)), func(c: Control) -> void:
			var center := Vector2(40, 40)
			c.draw_circle(center, 36.0 if i == 1 else 30.0, Color(0.1, 0.08, 0.14) if locked else SEAL_COLORS[i].darkened(0.45))
			c.draw_arc(center, 36.0 if i == 1 else 30.0, 0.0, TAU, 40, Color(_t["line"], 0.5) if locked else SEAL_COLORS[i], 5.0, true)
			if i == 1:
				c.draw_arc(center, 42.0, 0.0, TAU, 40, Color(_t["accent"], 0.5), 4.0, true))
		_label("?" if locked else ["I", "II", "III", "IV", "V", "VI"][i], 24, _t["text"], at - Vector2(40, 20), 80, HORIZONTAL_ALIGNMENT_CENTER, true)
	_frame(Rect2(o + Vector2(30, 200), Vector2(560, 190)), Color(_t["panel2"], 0.97))
	_label("SCEAU DE FER", 28, _t["text"], o + Vector2(56, 214), 0.0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label("Élites : 1 % · Ennemis +12 % PV et dégâts", 17, _t["muted"], o + Vector2(56, 262), 320)
	_label("Lieu : Temple englouti", 15, _t["muted"], o + Vector2(56, 340), 320)
	for k in 3:
		_icon_tile(["res://assets/icons/items/magnet_glove.png", "res://assets/icons/items/swift_rune.png", "res://assets/icons/items/hunter_star.png"][k],
			Rect2(o + Vector2(400 + k * 58, 244), Vector2(52, 52)))
	_label("Obtenues", 14, _t["price"], o + Vector2(400, 216))
	_button(Rect2(o + Vector2(190, 410), Vector2(240, 54)), "JOUER", true, 22, true)


func _victory(r: Rect2) -> void:
	_cell(r, "VICTOIRE !")
	var o := r.position
	_label("Vague 20 · 17 min 42 · 18 342 victimes", 17, _t["muted"], o + Vector2(20, 66), r.size.x - 40, HORIZONTAL_ALIGNMENT_CENTER)
	var names := ["Épée flamboyante", "Arc long", "Sceptre de givre"]
	var shares := [0.9, 0.6, 0.35]
	for k in 3:
		_label(names[k], 16, _t["text"], o + Vector2(36, 104 + k * 40), 150)
		_bar(Rect2(o + Vector2(190, 108 + k * 40), Vector2(260, 18)), shares[k], _t["accent"])
	_label("DÉBLOQUÉ", 18, _t["price"], o + Vector2(20, 236), r.size.x - 40, HORIZONTAL_ALIGNMENT_CENTER, true)
	for k in 3:
		var card := Rect2(o + Vector2(48 + k * 176, 270), Vector2(150, 124))
		_frame(card, Color(_t["panel2"], 0.97), true, 0.5)
		_icon_tile(["res://assets/icons/weapons/katana.png", "res://assets/icons/items/hunter_star.png", ""][k], Rect2(card.position + Vector2(40, 8), Vector2(70, 70)))
		if k == 2:
			_shard(card.position + Vector2(75, 43), 56.0)
		_label(["Faux", "Étoile", "+120 éclats"][k], 15, _t["text"], card.position + Vector2(0, 86), 150, HORIZONTAL_ALIGNMENT_CENTER)
	_button(Rect2(o + Vector2(70, 420), Vector2(210, 52)), "Rejouer", true, 20, true)
	_button(Rect2(o + Vector2(330, 420), Vector2(210, 52)), "Menu", false, 20, true)


func _skin_shop(r: Rect2) -> void:
	_cell(r, "BOUTIQUE DE SKINS")
	var o := r.position
	_shard(o + Vector2(255, 78), 34.0)
	_label("340", 24, _t["accent"], o + Vector2(276, 62))
	for k in 4:
		_button(Rect2(o + Vector2(24 + k * 146, 100), Vector2(138, 40)), ["Novice", "Assassin", "Mage", "Archère"][k], k == 0, 17, true)
	var rarity := ["CLASSIQUE", "RARE", "LÉGENDAIRE"]
	var price := [180, 420, 850]
	var heroes := ["drifter", "drifter_m", "mage"]
	for k in 3:
		var card := Rect2(o + Vector2(24 + k * 190, 154), Vector2(176, 320))
		_frame(card, Color(_t["panel2"], 0.97), k == 1, 0.6)
		_label(rarity[k], 13, [_t["muted"], _t["accent"], _t["price"]][k], card.position + Vector2(0, 14), 176, HORIZONTAL_ALIGNMENT_CENTER, true)
		_tex("res://assets/characters/cards/%s_card.png" % heroes[k], Rect2(card.position + Vector2(18, 40), Vector2(140, 190)))
		_button(Rect2(card.position + Vector2(18, 252), Vector2(140, 44)), "", k == 1, 16, true)
		_label(str(price[k]), 20, Color.WHITE if k == 1 else _t["price"], card.position + Vector2(36, 261), 60, HORIZONTAL_ALIGNMENT_CENTER)
		_shard(card.position + Vector2(108, 274), 26.0)


func _progression(r: Rect2) -> void:
	_cell(r, "PROGRESSION")
	var o := r.position
	_button(Rect2(o + Vector2(70, 70), Vector2(220, 40)), "Progression", true, 18, true)
	_button(Rect2(o + Vector2(310, 70), Vector2(220, 40)), "Collection", false, 18, true)
	var rows := [["Sceau de Fer vaincu", "Gagner au sceau de Fer", true], ["Sceau d'Argent vaincu", "Gagner au sceau d'Argent", true],
		["Sceau d'Or vaincu", "Gagner au sceau d'Or", false], ["Tueur de Chevalier démon", "Vaincre le boss final", false],
		["Thésauriseur", "Détenir 300 pièces d'or", false]]
	for k in rows.size():
		var y := 128.0 + k * 68.0
		_frame(Rect2(o + Vector2(30, y), Vector2(530, 60)), Color(_t["panel2"], 0.97), false, 0.4)
		_label("✔" if rows[k][2] else "·", 24, _t["accent"] if rows[k][2] else _t["muted"], o + Vector2(46, y + 12))
		_label(rows[k][0], 18, _t["text"] if rows[k][2] else _t["muted"], o + Vector2(84, y + 4))
		_label(rows[k][1], 13, _t["muted"], o + Vector2(84, y + 32))
		_icon_tile("res://assets/icons/items/hunter_star.png", Rect2(o + Vector2(498, y + 7), Vector2(46, 46)))


func _pause_settings(r: Rect2) -> void:
	_cell(r, "PAUSE · PARAMÈTRES")
	var o := r.position
	var names := ["Reprendre", "Paramètres", "Recommencer", "Menu principal"]
	for k in 4:
		_button(Rect2(o + Vector2(24, 72 + k * 60), Vector2(230, 48)), names[k], k == 0, 18, true)
	var sliders := [["Musique", 0.7], ["Effets", 0.85], ["Interface", 0.5]]
	for k in 3:
		_label(sliders[k][0], 17, _t["text"], o + Vector2(290, 72 + k * 56))
		_bar(Rect2(o + Vector2(290, 100 + k * 56), Vector2(290, 16)), sliders[k][1], _t["line"])
	_label("Barre de vie du héros", 16, _t["text"], o + Vector2(290, 246))
	_canvas(Rect2(o + Vector2(520, 244), Vector2(58, 28)), func(c: Control) -> void:
		var pts := _shape(Rect2(Vector2.ZERO, c.size), 1)
		c.draw_colored_polygon(pts, Color(_t["cta1"], 0.9))
		c.draw_polyline(_close(pts), _t["line"], 2.0, true)
		c.draw_circle(Vector2(c.size.x - 14, 14), 9.0, Color.WHITE))
	_label("Langue", 16, _t["text"], o + Vector2(290, 292))
	_button(Rect2(o + Vector2(400, 284), Vector2(178, 40)), "Français", false, 16, true)
	_label("Texte agrandi", 16, _t["text"], o + Vector2(290, 344))
	_button(Rect2(o + Vector2(400, 336), Vector2(178, 40)), "Normal", false, 16, true)
	_label("A  Valider      B  Retour", 15, _t["muted"], o + Vector2(24, 430), r.size.x - 48, HORIZONTAL_ALIGNMENT_CENTER)
