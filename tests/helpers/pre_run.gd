extends GutHookScript
## Runs before every test: the Settings autoload uses a throwaway file so tests
## never read or write the player's settings or profile.


func run() -> void:
	SafeFile.remove(Settings.TEST_PATH)
	Settings.path = Settings.TEST_PATH
	Settings.load_settings()
	TranslationServer.set_locale("en")
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.path = SaveService.TEST_PATH
	SaveService.load_profile()
