class_name PreviewSceneManager
extends RefCounted

## Handle NPC scene loading dan sprite references

# Scene instance
var npc_scene_instance: Node = null
var current_scene_path: String = ""

# Sprite references
var body_sprite: Sprite2D = null
var face_sprite: Sprite2D = null
var outfit_sprite: Sprite2D = null
var hair_sprite: Sprite2D = null
var hair2_sprite: Sprite2D = null
var accessory_sprite: Sprite2D = null

# Parent node untuk scene
var _parent_node: Node = null

signal scene_loaded(success: bool)
signal scene_cleared

func set_parent(parent: Node) -> void:
	_parent_node = parent

## Generate scene path berdasarkan npc_type dan gender
func get_scene_path(npc_type: String, gender: String) -> String:
	var type_name = npc_type.replace("NPC_", "")
	var gender_suffix = NPCDataManager.build_scene_suffix(gender)
	
	# Coba cari scene spesifik dulu
	var specific_path = "res://ScenesNPC/NPC%s%s.tscn" % [type_name, gender_suffix]
	if ResourceLoader.exists(specific_path):
		return specific_path
	
	# Fallback ke template scene
	var template_path = "res://ScenesNPC/TemplateNPC/NPCTemplate%s.tscn" % gender_suffix
	return template_path


## Load NPC scene berdasarkan type dan gender
func load_scene(npc_type: String, gender: String) -> bool:
	var scene_path = get_scene_path(npc_type, gender)
	
	# Skip jika scene sama
	if scene_path == current_scene_path and npc_scene_instance != null:
		return true
	
	# Hapus scene lama
	clear_scene()
	
	# Validasi scene exists
	if not ResourceLoader.exists(scene_path):
		push_warning("Scene not found: %s" % scene_path)
		current_scene_path = ""
		scene_loaded.emit(false)
		return false
	
	# Load dan instantiate
	var scene = load(scene_path) as PackedScene
	if scene == null:
		push_error("Failed to load scene: %s" % scene_path)
		current_scene_path = ""
		scene_loaded.emit(false)
		return false
	
	npc_scene_instance = scene.instantiate()
	
	if _parent_node:
		_parent_node.add_child(npc_scene_instance)
	
	# Setup sprite references
	_setup_sprite_references()
	
	current_scene_path = scene_path
	scene_loaded.emit(true)
	return true

## Setup references ke sprite nodes
func _setup_sprite_references() -> void:
	if npc_scene_instance == null:
		return
	
	# Cari CanvasGroup yang berisi sprites
	var canvas_group = npc_scene_instance.get_node_or_null("CanvasGroup")
	if canvas_group == null:
		canvas_group = npc_scene_instance
	
	body_sprite = canvas_group.get_node_or_null("CharacterBody") as Sprite2D
	face_sprite = canvas_group.get_node_or_null("CharacterFace") as Sprite2D
	outfit_sprite = canvas_group.get_node_or_null("CharacterOutfit") as Sprite2D
	hair_sprite = canvas_group.get_node_or_null("CharacterHair") as Sprite2D
	hair2_sprite = canvas_group.get_node_or_null("CharacterHair2") as Sprite2D
	accessory_sprite = canvas_group.get_node_or_null("CharacterAcc") as Sprite2D

## Clear current scene
func clear_scene() -> void:
	if npc_scene_instance != null:
		npc_scene_instance.queue_free()
		npc_scene_instance = null
	
	_clear_sprite_references()
	current_scene_path = ""
	scene_cleared.emit()

func _clear_sprite_references() -> void:
	body_sprite = null
	face_sprite = null
	outfit_sprite = null
	hair_sprite = null
	hair2_sprite = null
	accessory_sprite = null

## Check apakah scene sudah loaded
func has_scene() -> bool:
	return npc_scene_instance != null

## Get scene instance sebagai Node2D (untuk zoom/pan)
func get_scene_as_node2d() -> Node2D:
	if npc_scene_instance is Node2D:
		return npc_scene_instance as Node2D
	return null
