extends StaticBody2D
class_name Chest
## Chest - Coffre interactif avec système de loot et piège

signal opened(content: String)
signal restored()
signal trap_triggered()

enum ChestState { CLOSED, OPEN, EMPTY, RESTORED }

@export var content_item_id: String = ""
@export var is_trap: bool = false  # Coffre vide piège dès le départ
@export var restore_cost: int = 50  # Coût en K pour restaurer le coffre
@export var currency_amount: int = 0  # K à donner (généré procéduralement)
@export var is_gem_chest: bool = false  # Coffre à gemme (bonus x3)

const SPRITE_CLOSED = "res://assets/sprites/items/chest_closed.svg"
const SPRITE_OPEN = "res://assets/sprites/items/chest_open.svg"
const SPRITE_EMPTY = "res://assets/sprites/items/chest_empty.svg"

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var indicator: Node2D = null  # Créé dynamiquement

var state: ChestState = ChestState.CLOSED
var already_looted: bool = false
var unique_id: String = ""
var player_nearby: bool = false
var restored_by_player: bool = false  # Si un joueur a restauré ce coffre (piège)

func _ready() -> void:
	# Génère un ID unique basé sur la position
	unique_id = "chest_%d_%d" % [int(global_position.x), int(global_position.y)]

	# Connecter les signaux de détection
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_nearby)
		interaction_area.body_exited.connect(_on_player_left)

	_update_visual()
	_setup_indicator()

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
			# C'est un piège restauré par un autre joueur!
			_trigger_trap(player)

func _open_chest(_player: Node) -> void:
	state = ChestState.OPEN
	_play_open_animation()

	# Vérifier si c'est un piège (original ou restauré)
	if is_trap or restored_by_player:
		state = ChestState.EMPTY
		_trigger_trap(_player)
		return

	# Coffre avec currency (généré procéduralement)
	if currency_amount > 0:
		GameManager.add_currency(currency_amount)
		GameManager.on_currency_earned(currency_amount)
		already_looted = true

		if is_gem_chest:
			_show_gem_message(currency_amount)
		else:
			_show_currency_message(currency_amount)

		opened.emit("currency_%d" % currency_amount)
		_play_celebration_effect()
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

	# Animation de celebration
	_play_celebration_effect()

func _offer_restore_option(_player: Node) -> void:
	# Vérifier si le joueur a assez de K (monnaie)
	if GameManager.get_currency() >= restore_cost:
		GameManager.spend_currency(restore_cost)
		_restore_chest()
		print("Coffre restauré pour piéger d'autres joueurs! (-", restore_cost, "K)")
	else:
		print("Pas assez de K pour restaurer le coffre (besoin de ", restore_cost, "K)")

func _restore_chest() -> void:
	state = ChestState.RESTORED
	restored_by_player = true  # Maintenant c'est un piège!
	_update_visual()
	restored.emit()

	# Visual feedback
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 0.5), 0.2)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func _trigger_trap(player: Node) -> void:
	trap_triggered.emit()
	_show_trap_message()

	# Effet visuel de piège
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

	# Petit dégât ou effet au joueur?
	if player.has_method("take_damage"):
		# Optionnel: le piège fait des dégâts
		pass  # player.take_damage(1, Vector2.ZERO)

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

func _show_currency_message(amount: int) -> void:
	print("+ ", amount, "K trouvés!")
	# TODO: Afficher dans l'UI

func _show_gem_message(amount: int) -> void:
	print("*** GEMME! + ", amount, "K trouvés! ***")
	# TODO: Afficher dans l'UI avec effet spécial

func _setup_indicator() -> void:
	# Créer un indicateur visuel si pas déjà présent
	if not has_node("ChestIndicator"):
		indicator = Node2D.new()
		indicator.name = "ChestIndicator"
		add_child(indicator)

		var indicator_sprite = Sprite2D.new()
		indicator_sprite.name = "IndicatorSprite"
		indicator.add_child(indicator_sprite)
		indicator.position = Vector2(0, -30)
		indicator.visible = false

func _on_player_nearby(body: Node2D) -> void:
	if body is Player:
		player_nearby = true
		_show_indicator(true)

func _on_player_left(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
		_show_indicator(false)

func _show_indicator(visible_state: bool) -> void:
	if indicator:
		indicator.visible = visible_state and state == ChestState.CLOSED

		# Animation de flottement
		if visible_state:
			var tween = create_tween().set_loops()
			tween.tween_property(indicator, "position:y", -35, 0.5)
			tween.tween_property(indicator, "position:y", -30, 0.5)

func _play_celebration_effect() -> void:
	# Effet de particules ou animation de joie
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1, 1), 0.2)
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 0.5), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

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
