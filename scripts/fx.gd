class_name FX
extends RefCounted

# Particle effects: juice ke chheente, tukde, confetti, paani ka splash


static func burst(parent: Node, pos: Vector3, col: Color, amount: int, piece: float,
		vmin: float, vmax: float, use_box: bool = false, spread: float = 75.0) -> void:
	if not GameData.effects:
		return
	var p := CPUParticles3D.new()
	var mesh: PrimitiveMesh
	if use_box:
		var b := BoxMesh.new()
		b.size = Vector3(piece * 2.0, piece * 0.8, piece * 1.6)
		mesh = b
	else:
		var s := SphereMesh.new()
		s.radius = piece
		s.height = piece * 2.0
		s.radial_segments = 8
		s.rings = 4
		mesh = s
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.3
	mesh.material = m
	p.mesh = mesh
	p.amount = amount
	p.lifetime = 1.1
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = spread
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.gravity = Vector3(0, -16, 0)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(0.7, 0.8))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.color = col
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.get_tree().create_timer(1.8).timeout.connect(p.queue_free)


static func confetti(parent: Node, pos: Vector3, amount: int) -> void:
	if not GameData.effects:
		return
	var p := CPUParticles3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.14, 0.02, 0.2)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	b.material = m
	p.mesh = b
	p.amount = amount
	p.lifetime = 2.2
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 11.0
	p.gravity = Vector3(0, -7, 0)
	p.damping_min = 1.0
	p.damping_max = 2.5
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	g.colors = PackedColorArray([Color(1, 0.3, 0.3), Color(1, 0.85, 0.2), Color(0.3, 0.8, 1),
		Color(0.5, 1, 0.4), Color(1, 0.5, 1)])
	p.color_initial_ramp = g
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.get_tree().create_timer(2.6).timeout.connect(p.queue_free)


static func water_splash(parent: Node, pos: Vector3) -> void:
	burst(parent, pos, Color(0.85, 0.97, 1.0), 40, 0.09, 4.0, 8.0, false, 35.0)
