extends Control

## UI controller untuk Character Creation 

@onready var option_npc_type      : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowNPCType/OptionNPCType
@onready var option_gender        : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowGender/OptionGender
@onready var option_hair_type     : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowHairType/OptionHairType
@onready var option_hair_color    : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowHairColor/OptionHairColor
@onready var option_accessory     : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowAccessory/OptionAccessory
@onready var option_acc_color     : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowAccessoryColor/OptionAccessoryColor
@onready var option_outfit_color  : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowOutfitColor/OptionOutfitColor
@onready var option_eye_color     : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowEyeColor/OptionEyeColor
@onready var option_body_color    : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowBodyColor/OptionBodyColor
@onready var randomize_button     : Button       = $MarginContainer/MainLayout/RightPanel/ButtonRow/RandomizeButton
@onready var confirm_button       : Button       = $MarginContainer/MainLayout/RightPanel/ButtonRow/ConfirmButton
@onready var result_label         : Label        = $MarginContainer/MainLayout/RightPanel/ResultLabel

@onready var character_preview    : Control      = $MarginContainer/MainLayout/LeftPanel/PreviewFrame/PreviewArea/CharacterLayers

@onready var _hair_swatch_container   : HBoxContainer = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowHairColor/HairColorSwatch
@onready var _acc_swatch_container    : HBoxContainer = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowAccessoryColor/AccColorSwatch
@onready var _outfit_swatch_container : HBoxContainer = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowOutfitColor/OutfitColorSwatch
@onready var _eye_swatch_container    : HBoxContainer = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowEyeColor/EyeColorSwatch
@onready var _body_swatch_container   : HBoxContainer = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowBodyColor/BodyColorSwatch

var hair_swatches   : Array[ColorRect] = []
var acc_swatches    : Array[ColorRect] = []
var outfit_swatches : Array[ColorRect] = []
var eye_swatches    : Array[ColorRect] = []
var body_swatches   : Array[ColorRect] = []

var _data_manager: NPCDataManager

var _current_npc_type: String = ""
var _current_gender: String = ""

const GENDER_MAP = {
	"Young Male": "young_male",
	"Young Female": "young_female"
}
const GENDER_DISPLAY = {
	"young_male": "Young Male",
	"young_female": "Young Female"
}


func _ready() -> void:
	_data_manager = NPCDataManager.new()
	if not _data_manager.load_data():
		result_label.text = "Error: Failed to load NPC data"
		return

	_init_swatch_arrays()
	character_preview.set_data_manager(_data_manager)
	_connect_signals()
	_initialize_ui()
	_show_swatch_containers()

func _init_swatch_arrays() -> void:
	hair_swatches.assign(_hair_swatch_container.get_children().filter(func(c): return c is ColorRect))
	acc_swatches.assign(_acc_swatch_container.get_children().filter(func(c): return c is ColorRect))
	outfit_swatches.assign(_outfit_swatch_container.get_children().filter(func(c): return c is ColorRect))
	eye_swatches.assign(_eye_swatch_container.get_children().filter(func(c): return c is ColorRect))
	body_swatches.assign(_body_swatch_container.get_children().filter(func(c): return c is ColorRect))

func _connect_signals() -> void:
	option_npc_type.item_selected.connect(_on_npc_type_selected)
	option_gender.item_selected.connect(_on_gender_selected)
	option_hair_type.item_selected.connect(_on_selection_changed)
	option_hair_color.item_selected.connect(_on_hair_color_selected)
	option_accessory.item_selected.connect(_on_selection_changed)
	option_acc_color.item_selected.connect(_on_accessory_color_selected)
	option_outfit_color.item_selected.connect(_on_outfit_color_selected)
	option_eye_color.item_selected.connect(_on_eye_color_selected)
	option_body_color.item_selected.connect(_on_body_color_selected)
	randomize_button.pressed.connect(_on_randomize_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)

func _show_swatch_containers() -> void:
	_hair_swatch_container.visible   = true
	_acc_swatch_container.visible    = true
	_outfit_swatch_container.visible = true
	_eye_swatch_container.visible    = true
	_body_swatch_container.visible   = true

func _initialize_ui() -> void:
	# Populate NPC type dropdown
	var npc_types = _data_manager.get_npc_type_names()
	option_npc_type.clear()
	for npc_type in npc_types:
		option_npc_type.add_item(npc_type)
	
	# tetapkan init NPC type and gender
	if option_npc_type.item_count > 0:
		option_npc_type.select(0)
		_current_npc_type = option_npc_type.get_item_text(0)
		_update_gender_options()
		_update_property_options()

func _update_gender_options() -> void:
	var available_genders = _data_manager.get_available_genders(_current_npc_type)
	option_gender.clear()
	
	for gender_key in available_genders:
		var display_name = GENDER_DISPLAY.get(gender_key, gender_key)
		option_gender.add_item(display_name)
	
	if option_gender.item_count > 0:
		option_gender.select(0)
		var selected_text = option_gender.get_item_text(0)
		_current_gender = GENDER_MAP.get(selected_text, available_genders[0])

## Update ui berdasarkan property yang dipilih 
func _update_property_options() -> void:
	_populate_option_button(
		option_hair_type,
		NPCDataManager.extract_names(_data_manager.get_hair_types(_current_npc_type, _current_gender))
	)
	
	_populate_option_button(
		option_hair_color,
		NPCDataManager.extract_names(_data_manager.get_hair_colors(_current_npc_type, _current_gender))
	)
	
	_populate_option_button(
		option_accessory,
		NPCDataManager.extract_names(_data_manager.get_accessories(_current_npc_type, _current_gender))
	)
	
	_populate_option_button(
		option_acc_color,
		NPCDataManager.extract_names(_data_manager.get_accessory_colors(_current_npc_type, _current_gender))
	)
	
	_populate_option_button(
		option_outfit_color,
		NPCDataManager.extract_names(_data_manager.get_outfit_colors(_current_npc_type, _current_gender))
	)
	
	_populate_option_button(
		option_eye_color,
		NPCDataManager.extract_names(_data_manager.get_eye_colors(_current_npc_type, _current_gender))
	)
	
	_populate_option_button(
		option_body_color,
		NPCDataManager.extract_names(_data_manager.get_body_colors(_current_npc_type, _current_gender))
	)
	
	_update_all_swatches()
	_update_preview()

func _populate_option_button(button: OptionButton, items: Array) -> void:
	button.clear()
	for item in items:
		button.add_item(str(item))
	if button.item_count > 0:
		button.select(0)


func _update_swatch_colors(swatches: Array[ColorRect], color_name: String) -> void:
	var palette = _data_manager.get_color_palette(color_name)
	for i in range(min(swatches.size(), palette.size())):
		swatches[i].color = NPCDataManager.hex_to_color(palette[i])


func _update_all_swatches() -> void:
	# Update hair color swatches
	if option_hair_color.item_count > 0:
		var hair_color = option_hair_color.get_item_text(option_hair_color.selected)
		_update_swatch_colors(hair_swatches, hair_color)
	
	# Update acc color swatches
	if option_acc_color.item_count > 0:
		var acc_color = option_acc_color.get_item_text(option_acc_color.selected)
		_update_swatch_colors(acc_swatches, acc_color)
	
	# Update outfit color swatches
	if option_outfit_color.item_count > 0:
		var outfit_color = option_outfit_color.get_item_text(option_outfit_color.selected)
		_update_swatch_colors(outfit_swatches, outfit_color)
	
	# Update eye color swatches
	if option_eye_color.item_count > 0:
		var eye_color = option_eye_color.get_item_text(option_eye_color.selected)
		_update_swatch_colors(eye_swatches, eye_color)
	
	# Update body color swatches
	if option_body_color.item_count > 0:
		var body_color = option_body_color.get_item_text(option_body_color.selected)
		_update_swatch_colors(body_swatches, body_color)


func _update_preview() -> void:
	# Build result text
	var result_parts: Array = []
	
	if option_npc_type.item_count > 0:
		result_parts.append("Type: " + option_npc_type.get_item_text(option_npc_type.selected))
	if option_gender.item_count > 0:
		result_parts.append("Gender: " + option_gender.get_item_text(option_gender.selected))
	if option_hair_type.item_count > 0:
		result_parts.append("Hair: " + option_hair_type.get_item_text(option_hair_type.selected))
	if option_hair_color.item_count > 0:
		result_parts.append("Hair Color: " + option_hair_color.get_item_text(option_hair_color.selected))
	if option_accessory.item_count > 0:
		result_parts.append("Accessory: " + option_accessory.get_item_text(option_accessory.selected))
	
	result_label.text = " | ".join(result_parts)

	# display preview sprite
	_load_character_preview()


func _load_character_preview() -> void:
	var hair_type = ""
	var hair_color = ""
	var accessory = ""
	var acc_color = ""
	var outfit_color = ""
	var body_color = ""
	var eye_color = ""
	
	if option_hair_type.item_count > 0:
		hair_type = option_hair_type.get_item_text(option_hair_type.selected)
	if option_hair_color.item_count > 0:
		hair_color = option_hair_color.get_item_text(option_hair_color.selected)
	if option_accessory.item_count > 0:
		accessory = option_accessory.get_item_text(option_accessory.selected)
	if option_acc_color.item_count > 0:
		acc_color = option_acc_color.get_item_text(option_acc_color.selected)
	if option_outfit_color.item_count > 0:
		outfit_color = option_outfit_color.get_item_text(option_outfit_color.selected)
	if option_body_color.item_count > 0:
		body_color = option_body_color.get_item_text(option_body_color.selected)
	if option_eye_color.item_count > 0:
		eye_color = option_eye_color.get_item_text(option_eye_color.selected)
	
	# Display sesuai dengan konfigurasi yang dipilih
	character_preview.load_preview(
		_current_npc_type,
		_current_gender,
		hair_type,
		hair_color,
		accessory,
		acc_color,
		outfit_color,
		body_color,
		eye_color
	)

func _on_npc_type_selected(index: int) -> void:
	_current_npc_type = option_npc_type.get_item_text(index)
	_update_gender_options()
	_update_property_options()

func _on_gender_selected(index: int) -> void:
	var selected_text = option_gender.get_item_text(index)
	_current_gender = GENDER_MAP.get(selected_text, "young_male")
	_update_property_options()

func _on_selection_changed(_index: int) -> void:
	_update_preview()

func _on_hair_color_selected(index: int) -> void:
	var color_name = option_hair_color.get_item_text(index)
	_update_swatch_colors(hair_swatches, color_name)
	_update_preview()

func _on_accessory_color_selected(index: int) -> void:
	var color_name = option_acc_color.get_item_text(index)
	_update_swatch_colors(acc_swatches, color_name)
	_update_preview()

func _on_outfit_color_selected(index: int) -> void:
	var color_name = option_outfit_color.get_item_text(index)
	_update_swatch_colors(outfit_swatches, color_name)
	_update_preview()

func _on_eye_color_selected(index: int) -> void:
	var color_name = option_eye_color.get_item_text(index)
	_update_swatch_colors(eye_swatches, color_name)
	_update_preview()

func _on_body_color_selected(index: int) -> void:
	var color_name = option_body_color.get_item_text(index)
	_update_swatch_colors(body_swatches, color_name)
	_update_preview()

func _on_randomize_pressed() -> void:
	# Generate random config dengan NPCRandomizer
	var config = NPCRandomizer.generate_random_for_type_and_gender(
		_data_manager,
		_current_npc_type,
		_current_gender
	)
	
	# Apply random config ke UI
	_apply_configuration(config)
	
	result_label.text = "Randomized: " + config.hair_type + " (" + config.hair_color + ")"


func _on_confirm_pressed() -> void:
	result_label.text = "Saved"

func _apply_configuration(config: NPCRandomizer.NPCConfiguration) -> void:
	# pilih hair type dan color
	_select_option_by_text(option_hair_type, config.hair_type)
	_select_option_by_text(option_hair_color, config.hair_color)
	_on_hair_color_selected(option_hair_color.selected)
	
	# pilih acc type dan color
	_select_option_by_text(option_accessory, config.accessory)
	_select_option_by_text(option_acc_color, config.accessory_color)
	_on_accessory_color_selected(option_acc_color.selected)
	
	# pilih outfit color
	_select_option_by_text(option_outfit_color, config.outfit_color)
	_on_outfit_color_selected(option_outfit_color.selected)
	
	# pilih eye color
	_select_option_by_text(option_eye_color, config.eye_color)
	_on_eye_color_selected(option_eye_color.selected)
	
	# pilih body color
	_select_option_by_text(option_body_color, config.body_color)
	_on_body_color_selected(option_body_color.selected)

	_update_preview()

func _select_option_by_text(option_button: OptionButton, text: String) -> void:
	for i in range(option_button.item_count):
		if option_button.get_item_text(i) == text:
			option_button.select(i)
			return
	# jika tidak ditemukan, pilih index 0
