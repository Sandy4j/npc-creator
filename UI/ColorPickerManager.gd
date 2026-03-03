class_name ColorPickerManager
extends RefCounted

## Handle untuk menampilkan color picker

signal color_selected(category: String, color_name: String)

const SWATCH_SIZE := Vector2(28, 28)
const SWATCH_SELECTED_BORDER := Color(1, 1, 1, 1)
const SWATCH_NORMAL_BORDER := Color(0.3, 0.3, 0.35, 1)

var _data_manager: NPCDataManager

var _flow_map: Dictionary = {}
var _label_map: Dictionary = {}
var _selected_colors: Dictionary = {}


func _init(data_manager: NPCDataManager) -> void:
	_data_manager = data_manager


## register color picker dengan flow dan chip label
func register_picker(category: String, flow: FlowContainer, chip_label: Label) -> void:
	_flow_map[category] = flow
	_label_map[category] = chip_label
	_selected_colors[category] = ""

## GET selected color untuk category
func get_selected_color(category: String) -> String:
	return _selected_colors.get(category, "")
	

## Populate flow dengan color swatches
func populate(category: String, color_names: Array) -> void:
	var flow: FlowContainer = _flow_map.get(category)
	if flow == null:
		return
	
	# Clear children
	for child in flow.get_children():
		child.queue_free()
	
	if color_names.is_empty():
		_selected_colors[category] = ""
		_update_chip_label(category, "")
		return
	
	# Default select first
	_selected_colors[category] = str(color_names[0])
	
	for color_name in color_names:
		var btn = _create_swatch_button(str(color_name))
		flow.add_child(btn)
		btn.pressed.connect(_on_swatch_pressed.bind(category, str(color_name)))
	
	_update_flow_selection(category, str(color_names[0]))
	_update_chip_label(category, str(color_names[0]))


## select color by name untuk fungsi randomizer
func select_color(category: String, color_name: String) -> void:
	var flow: FlowContainer = _flow_map.get(category)
	if flow == null:
		return
	
	for child in flow.get_children():
		if child is Button and child.get_meta("color_name", "") == color_name:
			_selected_colors[category] = color_name
			_update_flow_selection(category, color_name)
			_update_chip_label(category, color_name)
			return


## update semua chip label
func update_all_chips() -> void:
	for category in _selected_colors.keys():
		_update_chip_label(category, _selected_colors[category])

func _on_swatch_pressed(category: String, color_name: String) -> void:
	_selected_colors[category] = color_name
	_update_flow_selection(category, color_name)
	_update_chip_label(category, color_name)
	color_selected.emit(category, color_name)

func _create_swatch_button(color_name: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = SWATCH_SIZE
	btn.tooltip_text = color_name
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var style = StyleBoxFlat.new()
	style.bg_color = SWATCH_NORMAL_BORDER
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 0)
	
	var palette = _data_manager.get_color_palette(color_name)
	for i in range(min(4, palette.size())):
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(5, 0)
		rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rect.color = NPCDataManager.hex_to_color(palette[i])
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(rect)
	
	panel.add_child(hbox)
	btn.add_child(panel)
	btn.set_meta("color_name", color_name)
	
	return btn

func _update_flow_selection(category: String, selected_name: String) -> void:
	var flow: FlowContainer = _flow_map.get(category)
	if flow == null:
		return
	
	for child in flow.get_children():
		if child is Button:
			var panel = child.get_child(0) as PanelContainer
			if panel:
				var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					var btn_name = child.get_meta("color_name", "")
					if btn_name == selected_name:
						style.border_color = SWATCH_SELECTED_BORDER
						style.border_width_left = 2
						style.border_width_right = 2
						style.border_width_top = 2
						style.border_width_bottom = 2
					else:
						style.border_color = SWATCH_NORMAL_BORDER
						style.border_width_left = 0
						style.border_width_right = 0
						style.border_width_top = 0
						style.border_width_bottom = 0

func _update_chip_label(category: String, color_name: String) -> void:
	var lbl: Label = _label_map.get(category)
	if lbl == null:
		return
	
	lbl.text = color_name
	_apply_chip_style(lbl)

func _apply_chip_style(lbl: Label) -> void:
	var bg_color := Color(0.2, 0.2, 0.25, 1)
	
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 1)
	
	lbl.add_theme_stylebox_override("normal", style)
	lbl.add_theme_constant_override("outline_size", 1)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))

