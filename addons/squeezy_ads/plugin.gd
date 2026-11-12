@tool
extends EditorPlugin
## Export ke waqt AdMob App ID: debug export = TEST, release export = asli (scripts/ads_config.gd).
## Poing plugin manifest mein "admob/general/android/app_id" setting likhta hai; hum use export
## ke dauran badalte hain aur baad mein wapas rakh dete hain (project.godot mein TEST ID hi rehta hai).

var _exp: AppIdExport


func _enter_tree() -> void:
	_exp = AppIdExport.new()
	add_export_plugin(_exp)


func _exit_tree() -> void:
	remove_export_plugin(_exp)
	_exp = null


class AppIdExport extends EditorExportPlugin:
	const KEY := "admob/general/android/app_id"
	const Cfg := preload("res://scripts/ads_config.gd")
	var _old: Variant = null

	func _get_name() -> String:
		return "SqueezyAdsAppId"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _export_begin(_features: PackedStringArray, is_debug: bool, _path: String, _flags: int) -> void:
		_old = ProjectSettings.get_setting(KEY, null)
		var id := Cfg.TEST_APP_ID if is_debug else Cfg.RELEASE_APP_ID
		ProjectSettings.set_setting(KEY, id)
		print("[SqueezyAds] AdMob App ID (%s): %s" % ["debug" if is_debug else "release", id])

	func _export_end() -> void:
		ProjectSettings.set_setting(KEY, _old)
