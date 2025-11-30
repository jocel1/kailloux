extends Node
## GameManager - Gestion globale du jeu (Platformer style)

signal scene_changed(scene_name: String)
signal game_paused(is_paused: bool)
signal player_died()
signal player_respawned()

enum GameState { MENU, PLAYING, PAUSED, DIALOGUE, INVENTORY }

var current_state: GameState = GameState.MENU
var current_scene_name: String = ""
var player: CharacterBody2D = null
var last_checkpoint_position: Vector2 = Vector2.ZERO
var last_checkpoint_scene: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and current_state in [GameState.PLAYING, GameState.PAUSED]:
		toggle_pause()

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit(true)
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		game_paused.emit(false)

func change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
	current_scene_name = scene_path.get_file().get_basename()
	scene_changed.emit(current_scene_name)

func start_game() -> void:
	current_state = GameState.PLAYING
	change_scene("res://scenes/world/maps/forgotten_caverns.tscn")

func register_player(player_node: CharacterBody2D) -> void:
	player = player_node
	# Set initial checkpoint if not set
	if last_checkpoint_position == Vector2.ZERO:
		last_checkpoint_position = player.global_position
		last_checkpoint_scene = current_scene_name

func get_player() -> CharacterBody2D:
	return player

func set_checkpoint(position: Vector2) -> void:
	last_checkpoint_position = position
	last_checkpoint_scene = current_scene_name

func respawn_player() -> void:
	if player:
		player_died.emit()

		# Wait a moment before respawn
		await get_tree().create_timer(0.5).timeout

		# Reset player position to checkpoint
		player.global_position = last_checkpoint_position

		# Reset player health
		if player.has_method("heal"):
			player.current_health = player.MAX_HEALTH

		# Reset velocity
		player.velocity = Vector2.ZERO

		# Reset invincibility
		player.is_invincible = false
		player.sprite.modulate = Color.WHITE

		player_respawned.emit()

func enter_dialogue() -> void:
	current_state = GameState.DIALOGUE

func exit_dialogue() -> void:
	current_state = GameState.PLAYING

func open_inventory() -> void:
	current_state = GameState.INVENTORY

func close_inventory() -> void:
	current_state = GameState.PLAYING
