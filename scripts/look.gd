class_name Look
extends RefCounted
## Game ka poora "look" (light, sky, paani, platform ke rang) EK jagah.
## Screen bahut safed/chamakdar lage to yahin se tune karo.
##
## Rule jo follow kiye hain:
##  - Koi bhi surface pure white (1.0) nahi: sabse halka rang ~0.9, taaki light padne
##    par bhi shading bachi rahe aur shape samajh aaye.
##  - Ek tez garam "sun" (key light) ek side se + thanda neela halka ambient (fill),
##    taaki platform ke top / aage / side wale face alag-alag brightness ke dikhein.
##  - Filmic tonemap + thoda contrast/saturation, taaki highlights jal kar safed na hon.
##  - Halka fog: door ki cheezein thodi fiki, paas ki saaf -> depth samajh aati hai.

# ------------------------------------------------------------- TUNING
const EXPOSURE := 0.85
const CONTRAST := 1.12
const SATURATION := 1.12

const SUN_COLOR := Color(1.0, 0.94, 0.84)
const SUN_ENERGY := 1.2
const SUN_ROT := Vector3(-48.0, 40.0, 0.0)   # top + front face bright, left side darker

const AMBIENT_COLOR := Color(0.52, 0.64, 0.82)
const AMBIENT_ENERGY := 0.42

const SKY_TOP := Color(0.12, 0.42, 0.88)
const SKY_HORIZON := Color(0.5, 0.76, 0.96)
const SEA_BOTTOM := Color(0.02, 0.3, 0.66)

const FOG_COLOR := Color(0.5, 0.72, 0.92)
const FOG_DENSITY := 0.006

# Platform colours: [top, side (upar), side (neeche, paani ke paas)]
const PLAT_NORMAL := [Color(0.88, 0.8, 0.68), Color(0.62, 0.68, 0.78), Color(0.3, 0.44, 0.64)]
const PLAT_HIGH := [Color(0.32, 0.56, 0.62), Color(0.2, 0.38, 0.44), Color(0.1, 0.24, 0.36)]
const PLAT_BOSS := [Color(1.0, 0.8, 0.3), Color(0.9, 0.62, 0.18), Color(0.55, 0.36, 0.14)]

const WATER_DEEP := Color(0.0, 0.3, 0.68)
const WATER_SHALLOW := Color(0.04, 0.46, 0.82)
const WATER_HORIZON := Color(0.34, 0.64, 0.9)


# ------------------------------------------------------------- ENVIRONMENT
static func environment() -> Environment:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = SKY_TOP
	sky_mat.sky_horizon_color = SKY_HORIZON
	sky_mat.sky_curve = 0.18
	sky_mat.ground_horizon_color = SKY_HORIZON
	sky_mat.ground_bottom_color = SEA_BOTTOM
	sky_mat.ground_curve = 0.05
	sky_mat.sun_angle_max = 8.0
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = AMBIENT_COLOR
	e.ambient_light_energy = AMBIENT_ENERGY
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = EXPOSURE
	e.tonemap_white = 3.0

	e.adjustment_enabled = true
	e.adjustment_brightness = 1.0
	e.adjustment_contrast = CONTRAST
	e.adjustment_saturation = SATURATION

	e.fog_enabled = true
	e.fog_light_color = FOG_COLOR
	e.fog_light_energy = 1.0
	e.fog_density = FOG_DENSITY
	e.fog_sky_affect = 0.0
	return e


static func sun() -> DirectionalLight3D:
	var s := DirectionalLight3D.new()
	s.rotation_degrees = SUN_ROT
	s.light_color = SUN_COLOR
	s.light_energy = SUN_ENERGY
	s.shadow_enabled = true
	s.shadow_opacity = 0.8
	s.shadow_blur = 1.5
	s.directional_shadow_max_distance = 35.0
	return s


# ------------------------------------------------------------- PLATFORM (pillar)
const _PILLAR_SHADER := """
shader_type spatial;
render_mode cull_back;

uniform vec3 top_col : source_color = vec3(0.93, 0.9, 0.84);
uniform vec3 side_col : source_color = vec3(0.78, 0.82, 0.88);
uniform vec3 base_col : source_color = vec3(0.36, 0.52, 0.72);
uniform float top_y = 0.0;
uniform float height = 2.0;
uniform vec2 center_xz = vec2(0.0);
uniform vec2 half_xz = vec2(1.0);

varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 c;
	if (w_nrm.y > 0.5) {
		// top: halka rang, kinare ki taraf thoda gehra -> "lip" dikhta hai
		vec2 d = abs(w_pos.xz - center_xz) / max(half_xz, vec2(0.01));
		float edge = max(d.x, d.y);
		c = top_col * mix(1.0, 0.8, smoothstep(0.88, 0.99, edge));
	} else {
		// side: upar se neeche gradient, paani ke paas gehra
		float depth = clamp((top_y - w_pos.y) / max(height, 0.01), 0.0, 1.0);
		c = mix(side_col, base_col, smoothstep(0.05, 1.0, depth));
		// top ke theek neeche patli gehri patti (outline jaisa)
		c *= mix(0.72, 1.0, smoothstep(0.03, 0.07, top_y - w_pos.y));
	}
	ALBEDO = c;
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
}
"""

static var _pillar_shader: Shader


static func pillar_material(top_center: Vector3, half: Vector3, bottom: float, kind: String = "normal") -> ShaderMaterial:
	if _pillar_shader == null:
		_pillar_shader = Shader.new()
		_pillar_shader.code = _PILLAR_SHADER
	var cols: Array = PLAT_NORMAL
	if kind == "high":
		cols = PLAT_HIGH
	elif kind == "boss":
		cols = PLAT_BOSS
	var m := ShaderMaterial.new()
	m.shader = _pillar_shader
	m.set_shader_parameter("top_col", cols[0])
	m.set_shader_parameter("side_col", cols[1])
	m.set_shader_parameter("base_col", cols[2])
	m.set_shader_parameter("top_y", top_center.y)
	m.set_shader_parameter("height", top_center.y - bottom)
	m.set_shader_parameter("center_xz", Vector2(top_center.x, top_center.z))
	m.set_shader_parameter("half_xz", Vector2(half.x, half.z))
	return m


# ------------------------------------------------------------- WATER
const WATER_SHADER := """
shader_type spatial;
uniform vec3 deep : source_color = vec3(0.0, 0.3, 0.68);
uniform vec3 shallow : source_color = vec3(0.08, 0.56, 0.9);
uniform vec3 horizon : source_color = vec3(0.45, 0.75, 0.95);
void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float n = sin(w.x * 1.3 + TIME * 1.1) * sin(w.z * 1.1 - TIME * 0.9)
			+ 0.5 * sin(w.x * 3.1 - TIME * 1.7) * sin(w.z * 2.7 + TIME * 1.3);
	vec3 c = mix(deep, shallow, 0.5 + 0.2 * n);
	// door ka paani aasmaan jaisa halka (fresnel)
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mix(c, horizon, fres * 0.7);
	ROUGHNESS = 0.18;
	SPECULAR = 0.45;
}
"""


static func water_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = WATER_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("deep", WATER_DEEP)
	m.set_shader_parameter("shallow", WATER_SHALLOW)
	m.set_shader_parameter("horizon", WATER_HORIZON)
	return m


## Bahut safed albedo ko thoda neeche laata hai (0.9 max), taaki light mein jal na jaaye.
static func tame(c: Color) -> Color:
	var mx := maxf(c.r, maxf(c.g, c.b))
	if mx > 0.9:
		var k := 0.9 / mx
		return Color(c.r * k, c.g * k, c.b * k, c.a)
	return c
