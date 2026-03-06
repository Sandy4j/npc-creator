extends Control

## UI controller untuk Character Creation 

@onready var option_npc_type      : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowNPCType/OptionNPCType
@onready var option_gender        : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowGender/OptionGender
@onready var option_outfit        : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowOutfit/OptionOutfit
@onready var option_hair_type     : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowHairType/OptionHairType
@onready var option_accessory     : OptionButton = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowAccessory/OptionAccessory
@onready var randomize_button     : Button       = $MarginContainer/MainLayout/RightPanel/ButtonRow/RandomizeButton
@onready var confirm_button       : Button       = $MarginContainer/MainLayout/RightPanel/ButtonRow/ConfirmButton
@onready var result_label         : Label        = $MarginContainer/MainLayout/RightPanel/ResultLabel
@onready var character_preview    : Control      = $MarginContainer/MainLayout/LeftPanel/PreviewFrame/PreviewArea/CharacterLayers

## FlowContainer references
@onready var _hair_color_flow     : FlowContainer = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowHairColor/HairColorFlow
@onready var _acc_color_flow      : FlowContainer = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowAccessoryColor/AccColorFlow
@onready var _outfit_color_flow   : FlowContainer = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowOutfitColor/OutfitColorFlow
@onready var _eye_color_flow      : FlowContainer = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowEyeColor/EyeColorFlow
@onready var _body_color_flow     : FlowContainer = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowBodyColor/BodyColorFlow

## Selected color chip labels
@onready var _lbl_sel_hair   : Label = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowHairColor/HairColorHeader/SelectedHairColor
@onready var _lbl_sel_acc    : Label = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowAccessoryColor/AccColorHeader/SelectedAccColor
@onready var _lbl_sel_outfit : Label = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowOutfitColor/OutfitColorHeader/SelectedOutfitColor
@onready var _lbl_sel_eye    : Label = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowEyeColor/EyeColorHeader/SelectedEyeColor
@onready var _lbl_sel_body   : Label = $MarginContainer/MainLayout/RightPanel/ScrollContainer/OptionsContainer/RowBodyColor/BodyColorHeader/SelectedBodyColor

## Managers
var _data_manager: NPCDataManager
var _mod_loader: ModLoader
var _color_picker: ColorPickerManager
var _asset_validator: AssetValidator

## Current selection state
var _current_age_type: String = ""
var _current_gender: String = ""
var _current_outfit: String = ""

## Color category keys
const COLOR_HAIR := "hair"
const COLOR_ACC := "accessory"
const COLOR_OUTFIT := "outfit"
const COLOR_EYE := "eye"
const COLOR_BODY := "body"

func _ready() -> void:
	_init_managers()
	if _data_manager == null:
		return
	
	_setup_color_pickers()
	_connect_signals()
	_initialize_ui()

func _init_managers() -> void:
	_data_manager = NPCDataManager.new()
	if not _data_manager.load_data():
		result_label.text = "Error: Failed to load NPC data"
		_data_manager = null
		return
	
	_mod_loader = ModLoader.new()
	_mod_loader.scan_mods()
	
	if _mod_loader.has_mod_npc_data():
		_data_manager.apply_mod_overrides(_mod_loader.get_mod_npc_data())
	
	_color_picker = ColorPickerManager.new(_data_manager)
	_asset_validator = AssetValidator.new(_data_manager, _mod_loader)
	
	character_preview.set_data_manager(_data_manager)
	character_preview.set_mod_loader(_mod_loader)

func _setup_color_pickers() -> void:
	_color_picker.register_picker(COLOR_HAIR, _hair_color_flow, _lbl_sel_hair)
	_color_picker.register_picker(COLOR_ACC, _acc_color_flow, _lbl_sel_acc)
	_color_picker.register_picker(COLOR_OUTFIT, _outfit_color_flow, _lbl_sel_outfit)
	_color_picker.register_picker(COLOR_EYE, _eye_color_flow, _lbl_sel_eye)
	_color_picker.register_picker(COLOR_BODY, _body_color_flow, _lbl_sel_body)
	
	_color_picker.color_selected.connect(_on_color_selected)

func _connect_signals() -> void:
	option_npc_type.item_selected.connect(_on_npc_type_selected)
	option_gender.item_selected.connect(_on_gender_selected)
	option_outfit.item_selected.connect(_on_outfit_selected)
	option_hair_type.item_selected.connect(_on_selection_changed)
	option_accessory.item_selected.connect(_on_selection_changed)
	randomize_button.pressed.connect(_on_randomize_pressed)
	confirm_button.pressed.connect(_on_reload_mod_pressed)

func _initialize_ui() -> void:
	var valid_ages = _asset_validator.get_valid_age_types()
	option_npc_type.clear()
	for age in valid_ages:
		option_npc_type.add_item(age)
	
	if option_npc_type.item_count > 0:
		option_npc_type.select(0)
		_current_age_type = option_npc_type.get_item_text(0)
		_update_gender_options()
		_update_outfit_options()
		_update_property_options()

func _update_gender_options() -> void:
	var valid_genders = _asset_validator.get_valid_genders_for_age(_current_age_type)
	
	option_gender.clear()
	for gender_key in valid_genders:
		option_gender.add_item(NPCDataManager.gender_key_to_display(gender_key))
	
	if option_gender.item_count > 0:
		option_gender.select(0)
		_current_gender = NPCDataManager.display_to_gender_key(option_gender.get_item_text(0))

func _update_outfit_options() -> void:
	var valid_outfits = _asset_validator.get_valid_outfits_for_gender(_current_gender)
	
	option_outfit.clear()
	for outfit in valid_outfits:
		option_outfit.add_item(outfit)
	
	if option_outfit.item_count > 0:
		option_outfit.select(0)
		_current_outfit = option_outfit.get_item_text(0)
	else:
		_current_outfit = ""

func _update_property_options() -> void:
	_populate_option_button(
		option_hair_type,
		NPCDataManager.extract_names(_asset_validator.get_valid_hair_types(_current_outfit, _current_gender))
	)
	_populate_option_button(
		option_accessory,
		NPCDataManager.extract_names(_asset_validator.get_valid_accessories(_current_outfit, _current_gender))
	)
	
	# Populate color pickers - use AssetValidator for fallback to all colors
	_color_picker.populate(COLOR_HAIR, NPCDataManager.extract_names(_asset_validator.get_valid_hair_colors(_current_outfit, _current_gender)))
	_color_picker.populate(COLOR_ACC, NPCDataManager.extract_names(_asset_validator.get_valid_accessory_colors(_current_outfit, _current_gender)))
	_color_picker.populate(COLOR_OUTFIT, NPCDataManager.extract_names(_asset_validator.get_valid_outfit_colors(_current_outfit, _current_gender)))
	_color_picker.populate(COLOR_EYE, NPCDataManager.extract_names(_asset_validator.get_valid_eye_colors(_current_outfit, _current_gender)))
	_color_picker.populate(COLOR_BODY, NPCDataManager.extract_names(_asset_validator.get_valid_body_colors(_current_outfit, _current_gender)))
	
	_color_picker.update_all_chips()
	_update_preview()

func _populate_option_button(button: OptionButton, items: Array) -> void:
	button.clear()
	for item in items:
		button.add_item(str(item))
	if button.item_count > 0:
		button.select(0)


func _update_preview() -> void:
	var parts: Array = []
	if option_npc_type.item_count > 0:
		parts.append("Age: " + option_npc_type.get_item_text(option_npc_type.selected))
	if option_gender.item_count > 0:
		parts.append("Gender: " + option_gender.get_item_text(option_gender.selected))
	if option_outfit.item_count > 0:
		parts.append("Outfit: " + option_outfit.get_item_text(option_outfit.selected))
	if option_hair_type.item_count > 0:
		parts.append("Hair: " + option_hair_type.get_item_text(option_hair_type.selected))
	
	result_label.text = " | ".join(parts)
	_load_character_preview()

func _load_character_preview() -> void:
	var hair_type := ""
	var accessory := ""
	
	if option_hair_type.item_count > 0:
		hair_type = option_hair_type.get_item_text(option_hair_type.selected)
	if option_accessory.item_count > 0:
		accessory = option_accessory.get_item_text(option_accessory.selected)
	
	character_preview.load_preview(
		_current_outfit,
		_current_gender,
		hair_type,
		_color_picker.get_selected_color(COLOR_HAIR),
		accessory,
		_color_picker.get_selected_color(COLOR_ACC),
		_color_picker.get_selected_color(COLOR_OUTFIT),
		_color_picker.get_selected_color(COLOR_BODY),
		_color_picker.get_selected_color(COLOR_EYE)
	)

func _on_npc_type_selected(index: int) -> void:
	_current_age_type = option_npc_type.get_item_text(index)
	_update_gender_options()
	_update_outfit_options()
	_update_property_options()


func _on_gender_selected(index: int) -> void:
	_current_gender = NPCDataManager.display_to_gender_key(option_gender.get_item_text(index))
	_update_outfit_options()
	_update_property_options()

func _on_outfit_selected(index: int) -> void:
	_current_outfit = option_outfit.get_item_text(index)
	_update_property_options()

func _on_selection_changed(_index: int) -> void:
	_update_preview()

func _on_color_selected(_category: String, _color_name: String) -> void:
	_update_preview()

func _on_randomize_pressed() -> void:
	# Use AssetValidator for fallback when no JSON entry
	var config = NPCRandomizer.generate_random_with_validator(
		_asset_validator,
		_current_outfit,
		_current_gender
	)
	
	_select_option_by_text(option_hair_type, config.hair_type)
	_select_option_by_text(option_accessory, config.accessory)
	
	_color_picker.select_color(COLOR_HAIR, config.hair_color)
	_color_picker.select_color(COLOR_ACC, config.accessory_color)
	_color_picker.select_color(COLOR_OUTFIT, config.outfit_color)
	_color_picker.select_color(COLOR_EYE, config.eye_color)
	_color_picker.select_color(COLOR_BODY, config.body_color)
	
	_update_preview()
	result_label.text = "Randomized: " + config.hair_type + " (" + config.hair_color + ")"

func _on_reload_mod_pressed() -> void:
	_mod_loader.scan_mods()
	if _mod_loader.has_mod_npc_data():
		_data_manager.apply_mod_overrides(_mod_loader.get_mod_npc_data())

func _select_option_by_text(option_button: OptionButton, text: String) -> void:
	for i in range(option_button.item_count):
		if option_button.get_item_text(i) == text:
			option_button.select(i)
			return
