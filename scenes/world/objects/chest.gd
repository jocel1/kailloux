extends StaticBody2D
class_name Chest
## Chest - Coffre interactif avec système de loot

signal opened(content: String)
signal restored()

enum ChestState { CLOSED, OPEN, EMPTY, RESTORED }

@export var content_item_id: String = ""
@export var is_trap: bool = false  # Coffre vide piège

const SPRITE_CLOSED = "res://assets/sprites/items/chest_closed.svg"
const SPRITE_OPEN = "res://assets/sprites/items/chest_open.svg"
const SPRITE_EMPTY = "res://assets/sprites/items/chest_empty.svg"

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var state: ChestState = ChestState.CLOSED
var already_looted: bool = false
var unique_id: String = ""

func _ready() -> void:
	# Génère un ID unique basé sur la position
	unique_id = "chest_%d_%d" % [int(global_position.x), int(global_position.y)]
	_update_visual()

func interact(player: Node) -> void:
	match state:
		ChestState.CLOSED:
			_open_chest(player)
		ChestState.OPEN:
			if already_looted:
				_offer_restore_option(player)
		ChestState.EMPTY:
			_show_empty_message()
		ChestState.RESTORED:
			_show_restored_message()

func _open_chest(_player: Node) -> void:
	state = ChestState.OPEN
	_play_open_animation()

	if is_trap:
		# C'est un piège, coffre vide
		state = ChestState.EMPTY
		_show_trap_message()
		return

	if content_item_id.is_empty():
		state = ChestState.EMPTY
		_show_empty_message()
		return

	# Donner l'objet au joueur
	InventoryManager.add_item(content_item_id)
	already_looted = true
	opened.emit(content_item_id)

	_show_loot_message(content_item_id)

func _offer_restore_option(_player: Node) -> void:
	# TODO: Afficher UI de confirmation pour restaurer le coffre
	# Pour l'instant, restaurer directement
	_restore_chest()

func _restore_chest() -> void:
	state = ChestState.RESTORED
	_update_visual()
	restored.emit()

func _play_open_animation() -> void:
	if animation_player and animation_player.has_animation("open"):
		animation_player.play("open")
	else:
		_update_visual()

func _update_visual() -> void:
	var texture_path: String
	match state:
		ChestState.CLOSED:
			texture_path = SPRITE_CLOSED
		ChestState.OPEN:
			texture_path = SPRITE_OPEN
		ChestState.EMPTY:
			texture_path = SPRITE_EMPTY
		ChestState.RESTORED:
			texture_path = SPRITE_CLOSED  # Restauré = apparence fermée

	var texture = load(texture_path)
	if texture:
		sprite.texture = texture
	sprite.modulate = Color.WHITE

func _show_loot_message(item_id: String) -> void:
	print("Vous avez trouvé: ", item_id)
	# TODO: Afficher dans l'UI

func _show_empty_message() -> void:
	print("Le coffre est vide...")
	# TODO: Afficher dans l'UI

func _show_trap_message() -> void:
	print("C'était un piège! Le coffre est vide.")
	# TODO: Afficher dans l'UI

func _show_restored_message() -> void:
	print("Ce coffre a été restauré.")
	# TODO: Afficher dans l'UI

func get_save_data() -> Dictionary:
	return {
		"unique_id": unique_id,
		"state": state,
		"already_looted": already_looted
	}

func load_save_data(data: Dictionary) -> void:
	if data.unique_id == unique_id:
		state = data.state
		already_looted = data.already_looted
		_update_visual()
