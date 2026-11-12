class_name Audio
extends Node

# Sounds: agar res://sounds/<naam>.ogg/.wav mile to woh, warna code se bani hui sound.

static var I: Audio
const RATE := 22050

var sfx := {}
var pool: Array = []
var music_player: AudioStreamPlayer


func _ready() -> void:
	I = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_sounds()
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -11.0
	music_player.stream = _load_or("music", null)
	if music_player.stream == null:
		music_player.stream = _make_music()
	add_child(music_player)
	update_music()


static func play(sname: String, pitch: float = 1.0) -> void:
	if I == null or not GameData.sound:
		return
	var s = I.sfx.get(sname)
	if s == null:
		return
	for p in I.pool:
		if not p.playing:
			p.stream = s
			p.pitch_scale = pitch
			p.play()
			return
	I.pool[0].stream = s
	I.pool[0].play()


static func update_music() -> void:
	if I == null:
		return
	if GameData.music:
		if not I.music_player.playing:
			I.music_player.play()
	else:
		I.music_player.stop()


func _load_or(sname: String, fallback):
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://sounds/%s.%s" % [sname, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return fallback


# ---------------- Sound synth ----------------

func _make_sounds() -> void:
	var defs := {
		"jump": _tone(260, 620, 0.2, "tri", 0.5, 1.6),
		"up": _tone(520, 980, 0.12, "sine", 0.4, 1.5),
		"splat": _mix(_lowpass(_tone(0, 0, 0.32, "noise", 0.7, 2.5), 0.12), _tone(170, 55, 0.3, "sine", 0.6, 2.0)),
		"crush": _mix(_lowpass(_tone(0, 0, 0.25, "noise", 0.6, 3.0), 0.3), _tone(140, 45, 0.25, "square", 0.25, 2.5)),
		"break": _mix(_lowpass(_tone(0, 0, 0.35, "noise", 0.7, 4.0), 0.55), _tone(900, 300, 0.12, "tri", 0.3, 3.0)),
		"pop": _mix(_tone(950, 250, 0.1, "sine", 0.6, 1.5), _lowpass(_tone(0, 0, 0.06, "noise", 0.4, 2.0), 0.5)),
		"splash": _lowpass(_tone(0, 0, 0.6, "noise", 0.7, 1.8), 0.08),
		"click": _tone(820, 620, 0.05, "sine", 0.45, 2.0),
		"coin": _cat([_tone(988, 988, 0.07, "square", 0.18, 0.5), _tone(1319, 1319, 0.22, "square", 0.18, 2.0)]),
		"win": _cat([_tone(523, 523, 0.12, "tri", 0.5, 0.8), _tone(659, 659, 0.12, "tri", 0.5, 0.8),
			_tone(784, 784, 0.12, "tri", 0.5, 0.8), _tone(1047, 1047, 0.4, "tri", 0.5, 2.0)]),
		"lose": _tone(420, 140, 0.55, "tri", 0.5, 1.2),
	}
	for k in defs:
		var f = _load_or(k, null)
		sfx[k] = f if f != null else _wav(defs[k], false)


func _tone(f0: float, f1: float, dur: float, wave: String, vol: float, decay: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / n
		ph += TAU * lerpf(f0, f1, t) / RATE
		var s := 0.0
		match wave:
			"sine":
				s = sin(ph)
			"square":
				s = 1.0 if sin(ph) > 0.0 else -1.0
			"tri":
				s = asin(sin(ph)) * 0.6366
			"noise":
				s = randf_range(-1.0, 1.0)
		var env := pow(1.0 - t, decay) * minf(1.0, i / (RATE * 0.004))
		out[i] = s * vol * env
	return out


func _lowpass(a: PackedFloat32Array, k: float) -> PackedFloat32Array:
	var y := 0.0
	for i in a.size():
		y += k * (a[i] - y)
		a[i] = y * 1.6
	return a


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = (a[i] if i < a.size() else 0.0) + (b[i] if i < b.size() else 0.0)
	return out


func _cat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


func _add_at(buf: PackedFloat32Array, part: PackedFloat32Array, start: int) -> void:
	for i in part.size():
		if start + i < buf.size():
			buf[start + i] += part[i]


func _wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


# Khushnuma chhota background tune (8 second loop)
func _make_music() -> AudioStreamWAV:
	var beat := 0.5
	var total := int(16 * beat * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var C5 := 523.25
	var D5 := 587.33
	var E5 := 659.25
	var G5 := 783.99
	var A5 := 880.0
	var C6 := 1046.5
	var mel := [C5, E5, G5, E5, A5, G5, E5, 0, D5, E5, G5, A5, G5, 0, E5, 0,
		C5, E5, G5, C6, A5, G5, E5, D5, E5, 0, D5, C5, D5, 0, 0, 0]
	for i in mel.size():
		if mel[i] > 0:
			_add_at(buf, _tone(mel[i], mel[i], beat * 0.48, "tri", 0.16, 1.4), int(i * beat * 0.5 * RATE))
	var bass := [130.81, 130.81, 110.0, 110.0, 87.31, 87.31, 98.0, 98.0]
	for b in 16:
		var f: float = bass[b % 8]
		_add_at(buf, _tone(f, f, beat * 0.9, "sine", 0.22, 1.2), int(b * beat * RATE))
		_add_at(buf, _tone(90, 40, 0.09, "sine", 0.35, 2.0), int(b * beat * RATE))
		_add_at(buf, _lowpass(_tone(0, 0, 0.04, "noise", 0.08, 2.0), 0.6), int((b + 0.5) * beat * RATE))
	return _wav(buf, true)
