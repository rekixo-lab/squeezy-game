class_name GameData
extends RefCounted

# Saari save hone wali cheezein: coins, kaunsa level khula hai, settings

const MAX_LEVEL := 200
const PATH := "user://save.cfg"

static var coins := 0
static var unlocked := 1        # sabse bada khula level
static var music := true
static var sound := true
static var effects := true


static func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	coins = int(cfg.get_value("game", "coins", 0))
	unlocked = clampi(int(cfg.get_value("game", "unlocked", cfg.get_value("game", "level", 1))), 1, MAX_LEVEL)
	music = bool(cfg.get_value("settings", "music", true))
	sound = bool(cfg.get_value("settings", "sound", true))
	effects = bool(cfg.get_value("settings", "effects", true))


static func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "coins", coins)
	cfg.set_value("game", "unlocked", unlocked)
	cfg.set_value("settings", "music", music)
	cfg.set_value("settings", "sound", sound)
	cfg.set_value("settings", "effects", effects)
	cfg.save(PATH)


static func complete_level(level: int) -> void:
	if level >= unlocked and level < MAX_LEVEL:
		unlocked = level + 1
	save_data()
