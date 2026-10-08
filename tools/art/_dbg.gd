extends SceneTree
func _initialize() -> void:
	var s := ShopScreen.new()
	root.add_child(s)
	await process_frame
	await process_frame
	var b: Button = s._reroll
	print("icon=", b.icon, " expand=", b.expand_icon, " min=", b.get_minimum_size(), " size=", b.size, " text='", b.text, "' vis=", b.is_visible_in_tree())
	quit()
