extends GutHookScript
## Runs before every test: the Settings autoload uses a throwaway file so tests
## never read or write the player's settings.


func run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.TEST_PATH))
	Settings.path = Settings.TEST_PATH
	Settings.load_settings()
	TranslationServer.set_locale("en")
