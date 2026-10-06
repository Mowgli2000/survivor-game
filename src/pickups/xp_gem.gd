class_name XpGem
extends RefCounted
## Data of one passive pickup, updated and drawn by PickupManager (one canvas item draws
## them all: batched, no node per pickup): a mana crystal (XP) or a gold coin (materials,
## the money of the shop). Two looks so the player tells them apart.

const SIZE := 7.0
## Illustrated mana crystal (art bible style), drawn ~2x smaller than its texture.
const TEXTURE := preload("res://assets/sprites/pickups/crystal.png")
## Merged crystals (big values) turn violet.
const BIG_TINT := Color(0.85, 0.62, 1.0)
const COIN_SIZE := 64

static var _coin_texture: ImageTexture

var position := Vector2.ZERO
## XP carried by a crystal.
var value: int = 1
## True for a material coin: `coins` materials instead of `value` XP.
var is_material: bool = false
var coins: float = 0.0
var attracted: bool = false
var speed: float = 0.0
## Player number the pickup flies to once attracted.
var target: int = 0


func reset(pos: Vector2, p_value: int) -> void:
	position = pos
	value = p_value
	is_material = false
	coins = 0.0
	attracted = false
	target = 0
	speed = 0.0


## A material coin worth `amount` materials (fractions are kept: see Wallet.add_scaled).
func reset_material(pos: Vector2, amount: float) -> void:
	reset(pos, 0)
	is_material = true
	coins = amount


func add_value(amount: int) -> void:
	value += amount


func add_coins(amount: float) -> void:
	coins += amount


## Draws the pickup centered on its position on `canvas` (the manager's draw).
func draw(canvas: CanvasItem) -> void:
	if is_material:
		var t := clampf(log(maxf(coins, 1.0)) / log(30.0), 0.0, 1.0)
		var size := SIZE * 2.9 * (1.0 + 0.9 * t)
		canvas.draw_texture_rect(coin_texture(), Rect2(position - Vector2(size, size) * 0.5, Vector2(size, size)), false)
		return
	# Mana crystal (art bible): bigger and more violet as the value grows (merged gems).
	var t := clampf(log(float(value)) / log(50.0), 0.0, 1.0)
	var height := SIZE * 3.2 * (1.0 + t)
	var width := height * TEXTURE.get_width() / TEXTURE.get_height()
	canvas.draw_texture_rect(TEXTURE, Rect2(position - Vector2(width, height) * 0.5, Vector2(width, height)), false,
		Color.WHITE.lerp(BIG_TINT, t))


## Gold coin drawn once into a texture: ink outline, flat gold, a darker inner ring and a
## light glint. A texture lets all the coins share the crystals' draw batches.
static func coin_texture() -> ImageTexture:
	if _coin_texture != null:
		return _coin_texture
	var image := Image.create(COIN_SIZE, COIN_SIZE, true, Image.FORMAT_RGBA8)
	var center := Vector2(COIN_SIZE, COIN_SIZE) * 0.5
	var outer := COIN_SIZE * 0.5 - 1.0
	var gold := Color(1.0, 0.82, 0.2)
	var dark := Color(0.78, 0.55, 0.08)
	var ink := Color(0.1, 0.07, 0.04)
	for y in COIN_SIZE:
		for x in COIN_SIZE:
			var offset := Vector2(x + 0.5, y + 0.5) - center
			var d := offset.length()
			var color := Color(0, 0, 0, 0)
			if d <= outer:
				color = ink
			if d <= outer * 0.82:
				color = gold
			if d <= outer * 0.62 and d >= outer * 0.5:
				color = dark
			# Glint: a short arc on the upper left of the rim.
			var angle := offset.angle()
			if d <= outer * 0.76 and d >= outer * 0.66 and angle > -2.6 and angle < -1.7:
				color = Color(1.0, 0.97, 0.8)
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	_coin_texture = ImageTexture.create_from_image(image)
	return _coin_texture
