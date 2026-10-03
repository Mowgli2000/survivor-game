extends Node
## Scene changes between the main menu and a run (autoload "SceneRouter", ADR 0013).
## Unpauses the tree and stops sounds before switching. No run logic here.
## Example: a "Play" button calls `SceneRouter.goto_run()`.

const MAIN_MENU := "res://src/ui/main_menu/main_menu.tscn"
const RUN := "res://src/run/run.tscn"


func goto_main_menu() -> void:
	_change(MAIN_MENU)


func goto_run() -> void:
	_change(RUN)


func quit() -> void:
	get_tree().quit()


func _change(path: String) -> void:
	get_tree().paused = false
	Audio.stop_all()
	get_tree().change_scene_to_file.call_deferred(path)
