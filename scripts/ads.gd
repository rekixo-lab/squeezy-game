class_name Ads
extends Node
## AdMob interstitial (level complete ke baad) + Google UMP consent (GDPR).
## Niyam (scripts/ads_config.gd): level 1-2 par ad nahi, do ads ke beech 45s, ad taiyaar na ho
## ya internet na ho to game bina ruke aage. Desktop / editor par sab kuch no-op.
## Debug build = Google TEST ad IDs, release build = asli IDs.

static var I: Ads

var enabled := false             # Android + plugin mila
var can_request := false         # consent ke baad ads maang sakte hain
var initialized := false
var _ad: InterstitialAd = null
var _loading := false
var _retry_sec := 15.0
var _last_shown := -1000.0       # seconds (Time.get_ticks_msec)
var _on_done: Callable = Callable()
var _showing := false
var _was_muted := false


func _ready() -> void:
	I = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob")
	if not enabled:
		return
	_request_consent()


# ------------------------------------------------------------------ consent (UMP)

func _request_consent() -> void:
	var params := ConsentRequestParameters.new()
	if OS.is_debug_build() and OS.has_feature("ump_eea_test"):
		var dbg := ConsentDebugSettings.new()
		dbg.debug_geography = DebugGeography.Values.EEA
		params.consent_debug_settings = dbg
	UserMessagingPlatform.consent_information.update(params,
		func() -> void:
			if UserMessagingPlatform.consent_information.get_is_consent_form_available():
				_load_consent_form()
			else:
				_after_consent(),
		func(err: FormError) -> void:
			# Internet nahi / form nahi: pehle se diya consent ho to usi se chalo
			_log("consent update fail: %s" % (err.message if err else "?"))
			_after_consent())


func _load_consent_form() -> void:
	UserMessagingPlatform.load_consent_form(
		func(form: ConsentForm) -> void:
			if UserMessagingPlatform.consent_information.get_consent_status() \
					== ConsentInformation.ConsentStatus.REQUIRED:
				form.show(func(_e: FormError) -> void:
					_after_consent())
			else:
				_after_consent(),
		func(err: FormError) -> void:
			_log("consent form load fail: %s" % (err.message if err else "?"))
			_after_consent())


func _after_consent() -> void:
	var st := UserMessagingPlatform.consent_information.get_consent_status()
	can_request = st == ConsentInformation.ConsentStatus.OBTAINED \
		or st == ConsentInformation.ConsentStatus.NOT_REQUIRED
	_log("consent status=%d can_request=%s" % [st, can_request])
	if can_request and not initialized:
		_init_sdk()


## Settings mein "Privacy" button dikhana hai? (EEA/UK users ke liye zaroori)
func privacy_options_required() -> bool:
	return enabled and UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options() -> void:
	if not enabled:
		return
	UserMessagingPlatform.show_privacy_options_form(func(_e: FormError) -> void:
		_after_consent())


# ------------------------------------------------------------------ SDK + interstitial

func _init_sdk() -> void:
	var rc := RequestConfiguration.new()
	rc.max_ad_content_rating = AdsConfig.MAX_CONTENT_RATING
	MobileAds.set_request_configuration(rc)
	var l := OnInitializationCompleteListener.new()
	l.on_initialization_complete = func(_s: InitializationStatus) -> void:
		initialized = true
		_log("MobileAds initialized (%s)" % ("TEST ids" if OS.is_debug_build() else "release ids"))
		_load()
	MobileAds.initialize(l)


func _load() -> void:
	if not initialized or not can_request or _loading or _ad != null:
		return
	_loading = true
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_loading = false
		_retry_sec = 15.0
		_ad = ad
		_log("interstitial loaded")
	cb.on_ad_failed_to_load = func(err: LoadAdError) -> void:
		_loading = false
		_log("interstitial load fail: %s" % (err.message if err else "?"))
		# Internet nahi ho sakta: thodi der baad phir (har baar zyada intezaar, max 5 min)
		get_tree().create_timer(_retry_sec, true).timeout.connect(_load)
		_retry_sec = minf(_retry_sec * 2.0, 300.0)
	InterstitialAdLoader.new().load(AdsConfig.interstitial_id(), AdRequest.new(), cb)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Level jeetne ke baad (NEXT dabane par) bulao. Ad dikhe ya na dikhe, on_done ZAROOR chalega.
func level_complete(level: int, on_done: Callable) -> void:
	var ok := enabled and can_request and _ad != null and not _showing \
		and level >= AdsConfig.FIRST_AD_LEVEL and _now() - _last_shown >= AdsConfig.MIN_GAP_SEC
	if not ok:
		on_done.call()
		_load()
		return
	_on_done = on_done
	_showing = true
	var ad := _ad
	_ad = null
	var fs := FullScreenContentCallback.new()
	fs.on_ad_showed_full_screen_content = func() -> void:
		_last_shown = _now()
	fs.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_finish()
	fs.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
		_log("interstitial show fail: %s" % (err.message if err else "?"))
		ad.destroy()
		_finish()
	ad.full_screen_content_callback = fs
	_mute(true)
	ad.show()
	# Suraksha: agar SDK koi callback na de to bhi game atke nahi
	get_tree().create_timer(90.0, true).timeout.connect(func() -> void:
		if _showing:
			_log("ad timeout, aage badh rahe hain")
			_finish())


func _finish() -> void:
	if not _showing:
		return
	_showing = false
	_mute(false)
	var cb := _on_done
	_on_done = Callable()
	if cb.is_valid():
		cb.call()
	_load()


# Ad ke dauran game ki saari awaaz (music + sound) band
func _mute(on: bool) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if on:
		_was_muted = AudioServer.is_bus_mute(bus)
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, _was_muted)


func _log(msg: String) -> void:
	print("[Ads] ", msg)
