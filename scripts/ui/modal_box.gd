class_name ModalBox
extends Control

# Popup box: title + text + buttons (Help, Shop, Level Complete, Oops ...)

var panel: PanelContainer
var vbox: VBoxContainer


static func open(parent: Node, title: String, body: String) -> ModalBox:
	var m := ModalBox.new()
	parent.add_child(m)
	m._build(title, body)
	return m


func _build(title: String, body: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.12, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.17, 0.42)
	sb.border_color = Color(0.36, 0.42, 0.95)
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(40)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 10)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 30
	sb.content_margin_bottom = 34
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(600, 0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 22)
	panel.add_child(vbox)
	var t := UIKit.label(title, 62, Color(1.0, 0.85, 0.15), UIKit.PURPLE_DARK, 18)
	vbox.add_child(t)
	if body != "":
		var b := UIKit.label(body, 34, Color.WHITE, Color(0.08, 0.1, 0.3), 8)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(520, 0)
		vbox.add_child(b)

	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)


func add_button(col: String, text: String, cb: Callable) -> TextureButton:
	var b := UIKit.text_button(col, text, Vector2(440, 104), 46)
	vbox.add_child(b)
	b.pressed.connect(cb)
	return b


func close() -> void:
	queue_free()
