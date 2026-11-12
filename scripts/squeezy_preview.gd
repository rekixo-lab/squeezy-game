extends Node3D
## Open scenes/squeezy_preview.tscn and press F6 to check the character:
## buttons play every animation, the slider changes fatness.

var man: SqueezyMan
var spin := false


func _ready() -> void:
	# same look as the real game (scripts/look.gd)
	var env := WorldEnvironment.new()
	env.environment = Look.environment()
	add_child(env)
	add_child(Look.sun())
	var cam := Camera3D.new()
	cam.position = Vector3(1.8, 1.6, 3.4)
	cam.fov = 40
	add_child(cam)
	cam.look_at(Vector3(0, 0.8, 0))
	var ground := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 0.4, 1.6)
	bm.material = Look.pillar_material(Vector3.ZERO, Vector3(0.8, 0, 0.8), -0.4)
	ground.mesh = bm
	ground.position.y = -0.2
	add_child(ground)

	man = SqueezyMan.new()
	add_child(man)

	var ui := VBoxContainer.new()
	ui.position = Vector2(16, 16)
	add_child(ui)
	for a in ["idle", "jump", "tuck", "fall", "smash", "sit", "victory", "fail", "sad"]:
		var b := Button.new()
		b.text = a
		b.pressed.connect(_on_button.bind(a))
		ui.add_child(b)
	var l := Label.new()
	l.text = "fat"
	ui.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.custom_minimum_size = Vector2(200, 30)
	s.value_changed.connect(func(v): man.set_fat(v))
	ui.add_child(s)
	var sp := CheckBox.new()
	sp.text = "flip spin (tuck)"
	sp.toggled.connect(func(on): spin = on)
	ui.add_child(sp)


func _on_button(a: String) -> void:
	man.set_flip_angle(0.0)
	match a:
		"jump": man.jump()
		"smash": man.smash(0.0)
		"victory": man.win()
		"sad": man.lose()
		"fail": man.fall_off()
		"fall": man.start_falling()
		_: man.play(a)


func _process(delta: float) -> void:
	if spin:
		man.pivot.rotate_x(-delta * TAU * 1.6)
