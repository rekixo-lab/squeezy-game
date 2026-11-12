class_name Player
extends Node3D

# Squeezy Man character (models/squeezy_man.glb + scripts/squeezy_man.gd).
# game.gd ke liye API purani jaisi hi hai: set_pose, add_flip, update_spin,
# finish_spin, squish, grow, cheer, reset, sit_h, STAND_H.
# Player ka origin = KAMAR (hips). Khade hone par pair origin se STAND_H neeche hote hain.

const MAN_SCALE := 1.15                 # character ka size (bada/chhota karna ho to yahi badlo)
const HIP_Y := 0.6                      # glb mein hips ki unchai (pair y=0)
const STAND_H := HIP_Y * MAN_SCALE
const SIT_H := 0.2
const MAX_BUTT := 2.3

var body: Node3D           # flips isi ko ghumate hain (pivot = kamar)
var man: SqueezyMan
var butt_size := 1.0       # 1 = shuru, MAX_BUTT = sabse mota
var pose := ""
var spin := 0.0
var spin_target := 0.0
var _fx_tween: Tween
var _crouch_ms := -10000


func _ready() -> void:
	body = Node3D.new()
	add_child(body)
	man = SqueezyMan.new()
	man.scale = Vector3.ONE * MAN_SCALE
	man.position.y = -STAND_H          # pair zameen par, origin kamar par
	man.rotation.y = PI                # glb ka front +Z hai, game aage -Z ki taraf jaata hai
	body.add_child(man)
	man.set_fat(0.0, true)
	set_pose("stand", 0.0)


# ---------------- Poses -> Squeezy Man animations ----------------

func set_pose(pname: String, dur: float) -> void:
	var prev := pose
	pose = pname
	if man == null or man.anim == null:
		return
	var blend := maxf(dur, 0.02)
	match pname:
		"stand":
			man.play("idle", blend)
		"crouch":
			_crouch_ms = Time.get_ticks_msec()
			man.jump()                 # crouch + launch, phir apne-aap tuck
		"tuck":
			# jump anim chal rahi ho to use poora hone do (woh khud tuck pe jaati hai)
			if prev == "crouch" and Time.get_ticks_msec() - _crouch_ms < 350:
				return
			man.play("tuck", blend)
		"sit":
			if prev != "sit":
				man.start_falling()    # pair aage, haath upar, butt pehle
		"fall":
			man.fall_off()             # paani mein girte waqt haath-pair maarna
		"win":
			man.win()                  # victory dance


# Baithne par kamar kitni upar hoti hai (moti kamar = thoda zyada)
func sit_h() -> float:
	return SIT_H + 0.12 * (butt_size - 1.0)


# ---------------- Flips ----------------

func add_flip() -> void:
	spin_target -= TAU


# true = abhi bhi ghoom raha hai
func update_spin(delta: float) -> bool:
	spin = move_toward(spin, spin_target, 13.0 * delta)
	body.rotation.x = spin
	return not is_equal_approx(spin, spin_target)


func finish_spin() -> void:
	spin = 0.0
	spin_target = 0.0
	body.rotation.x = 0.0


# ---------------- Effects ----------------

# Landing: butt-slam animation + pet ka jiggle
func squish() -> void:
	man.smash(0.0)
	var tw := create_tween()
	tw.tween_property(body, "scale", Vector3(1.12, 0.85, 1.12), 0.06)
	tw.tween_property(body, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Har cheez todne ke baad thoda mota (fat blend shape)
func grow(amount: float) -> void:
	butt_size = minf(butt_size + amount, MAX_BUTT)
	man.set_fat((butt_size - 1.0) / (MAX_BUTT - 1.0))


func cheer() -> void:
	if _fx_tween:
		_fx_tween.kill()
	_fx_tween = create_tween().set_loops(4)
	_fx_tween.tween_property(body, "position:y", 0.3, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_fx_tween.tween_property(body, "position:y", 0.0, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func reset(pos: Vector3) -> void:
	if _fx_tween:
		_fx_tween.kill()
	position = pos
	finish_spin()
	body.position = Vector3.ZERO
	body.scale = Vector3.ONE
	butt_size = 1.0
	man.set_fat(0.0, true)
	pose = ""
	set_pose("stand", 0.0)
