class_name SqueezyMan
extends Node3D
## Squeezy Man character controller (visuals only).
## Physics / jumping stays in player.gd - call these functions from there:
##   jump()            -> crouch + launch, then tucks into a ball (rotate this node for the flip)
##   start_falling()   -> legs forward, arms flailing, mouth open (just before landing)
##   smash(grow := 0.1)-> butt-slam squash + belly jiggle, then sits; gets fatter by `grow`
##   win() / lose() / fall_off()
##   set_fat(0..1)     -> 0 = starting chubby, 1 = maximum fat

signal smash_finished

const MODEL_PATH := "res://models/squeezy_man.glb"
const PIVOT_HEIGHT := 0.62
const LOOPING := ["idle", "tuck", "fall", "sit", "victory", "fail", "sad"]

@export_range(0.0, 1.0) var fat := 0.0:
	set(v):
		fat = clampf(v, 0.0, 1.0)
@export var blend_time := 0.08
@export var auto_blink := true

var model: Node3D
var pivot: Node3D           ## rotate THIS for the mid-air flip (it sits at belly height)
var anim: AnimationPlayer
var mesh: MeshInstance3D

var _fat_shown := 0.0
var _shape := {}            # blend shape name -> index
var _blink_timer := 2.0
var _blink := 0.0
var _mouth := 0.0
var _mouth_target := 0.0
var _brows := 0.0
var _brows_target := 0.0
var _jiggle := 0.0          # squash & stretch spring
var _jiggle_v := 0.0
var _state := ""


func _ready() -> void:
	pivot = Node3D.new()
	pivot.name = "FlipPivot"
	pivot.position = Vector3(0, PIVOT_HEIGHT, 0)
	add_child(pivot)
	model = load(MODEL_PATH).instantiate()
	model.position = Vector3(0, -PIVOT_HEIGHT, 0)
	pivot.add_child(model)
	anim = model.find_child("AnimationPlayer", true, false)
	for m in model.find_children("*", "MeshInstance3D", true, false):
		mesh = m
		break
	for n in ["fat", "blink", "mouth_open", "brows_up"]:
		_shape[n] = mesh.find_blend_shape_by_name(n)
	_setup_materials()
	if anim:
		for a in LOOPING:
			if anim.has_animation(a):
				anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		anim.animation_finished.connect(_on_anim_finished)
	_fat_shown = fat
	play("idle")


func _setup_materials() -> void:
	# Colours (incl. baked AO + blush) live in vertex colours.
	for i in mesh.get_surface_override_material_count():
		var src = mesh.mesh.surface_get_material(i)
		if src is StandardMaterial3D:
			var mat: StandardMaterial3D = src.duplicate()
			mat.vertex_color_use_as_albedo = true
			mat.vertex_color_is_srgb = false
			if mat.resource_name == "Glint":
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			elif mat.resource_name in ["Skin", "Cloth"]:
				mat.rim_enabled = true
				mat.rim = 0.15
				mat.rim_tint = 0.3
			mesh.set_surface_override_material(i, mat)


# ------------------------------------------------------------------ public API
func play(state: String, blend := -1.0) -> void:
	if anim == null or not anim.has_animation(state):
		return
	_state = state
	anim.play(state, blend_time if blend < 0.0 else blend)
	match state:
		"fall", "fail":
			_mouth_target = 1.0
			_brows_target = 1.0
		"victory":
			_mouth_target = 0.6
			_brows_target = 0.6
		"sad":
			_mouth_target = 0.0
			_brows_target = 0.0
		_:
			_mouth_target = 0.0
			_brows_target = 0.0


func jump() -> void:
	play("jump", 0.05)
	anim.queue("tuck")


func start_falling() -> void:
	play("fall", 0.12)


func smash(grow := 0.1) -> void:
	play("smash", 0.03)
	anim.queue("sit")
	fat = fat + grow
	_jiggle_v -= 9.0            # big squash, the spring bounces it back
	_mouth = 1.0
	_brows = 1.0


func win() -> void:
	play("victory", 0.15)


func lose() -> void:
	play("sad", 0.2)


func fall_off() -> void:
	play("fail", 0.1)


func set_flip_angle(radians: float) -> void:
	pivot.rotation.x = radians


func set_fat(v: float, instant := false) -> void:
	fat = v
	if instant:
		_fat_shown = fat


# ------------------------------------------------------------------ per-frame
func _process(delta: float) -> void:
	if mesh == null:
		return
	# fat grows with a little overshoot wobble
	_fat_shown = lerpf(_fat_shown, fat, 1.0 - exp(-8.0 * delta))
	# squash/stretch spring (belly jiggle)
	var k := 180.0
	var damp := 9.0
	_jiggle_v += (-k * _jiggle - damp * _jiggle_v) * delta
	_jiggle += _jiggle_v * delta
	var j := clampf(_jiggle, -0.35, 0.35)
	pivot.scale = Vector3(1.0 - j * 0.6, 1.0 + j, 1.0 - j * 0.6)
	pivot.position.y = PIVOT_HEIGHT * pivot.scale.y
	# face
	_mouth = lerpf(_mouth, _mouth_target, 1.0 - exp(-10.0 * delta))
	_brows = lerpf(_brows, _brows_target, 1.0 - exp(-10.0 * delta))
	if auto_blink:
		_blink_timer -= delta
		if _blink_timer <= 0.0:
			_blink_timer = randf_range(1.8, 4.5)
			_blink = 1.0
	_blink = maxf(0.0, _blink - delta * 7.0)
	_set_shape("fat", _fat_shown)
	_set_shape("blink", _blink_curve())
	_set_shape("mouth_open", _mouth)
	_set_shape("brows_up", _brows)


func _blink_curve() -> float:
	if _state == "sad":
		return 0.45
	# 0 -> 1 -> 0 over the blink
	return sin(clampf(_blink, 0.0, 1.0) * PI)


func _set_shape(n: String, v: float) -> void:
	var i: int = _shape.get(n, -1)
	if i >= 0:
		mesh.set_blend_shape_value(i, v)


func _on_anim_finished(a: StringName) -> void:
	if a == &"smash":
		smash_finished.emit()
