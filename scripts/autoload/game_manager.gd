extends Node
## GameManager - Gestion globale du jeu (Platformer style)

signal scene_changed(scene_name: String)
signal game_paused(is_paused: bool)
signal player_died()
signal currency_changed(new_amount: int)
signal level_changed(new_level: int)
signal level_completed_signal(level: int, stats: Dictionary)

enum GameState { MENU, PLAYING, PAUSED, DIALOGUE, INVENTORY, LEVEL_TRANSITION }

var current_state: GameState = GameState.MENU
var current_scene_name: String = ""
var player: CharacterBody2D = null
var last_checkpoint_position: Vector2 = Vector2.ZERO
var last_checkpoint_scene: String = ""

# Système de monnaie (K)
var currency: int = 0  # Kailloux coins!

# Système de progression
var current_level: int = 1
var highest_level_reached: int = 1
var total_enemies_killed: int = 0
var level_start_time: float = 0.0
var level_enemies_killed: int = 0
var level_currency_earned: int = 0
var current_level_seed: int = 0  # Seed pour régénérer la même map
var is_restart: bool = false  # True si on restart après une mort

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
	# Lancer le jeu procédural
	start_procedural_game()

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
	player_died.emit()

	print("=== MORT DU JOUEUR ===")

	# Wait a moment before respawn
	await get_tree().create_timer(1.0).timeout

	# Marquer comme restart (même map)
	is_restart = true

	# Recharger le niveau actuel
	level_changed.emit(current_level)

func enter_dialogue() -> void:
	current_state = GameState.DIALOGUE

func exit_dialogue() -> void:
	current_state = GameState.PLAYING

func open_inventory() -> void:
	current_state = GameState.INVENTORY

func close_inventory() -> void:
	current_state = GameState.PLAYING

# Fonctions de monnaie (K)
func get_currency() -> int:
	return currency

func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)
	# Jouer le son de pièce
	if player and player.has_method("play_coin_sound"):
		player.play_coin_sound()
	print("+ ", amount, "K (Total: ", currency, "K)")

func spend_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		currency_changed.emit(currency)
		print("- ", amount, "K (Total: ", currency, "K)")
		return true
	return false

func has_currency(amount: int) -> bool:
	return currency >= amount

# Fonctions de progression de niveau
func start_procedural_game() -> void:
	current_level = 1
	currency = 0
	total_enemies_killed = 0
	current_state = GameState.PLAYING
	load_procedural_level(current_level)

func load_procedural_level(level: int) -> void:
	current_level = level
	level_enemies_killed = 0
	level_currency_earned = 0
	level_start_time = Time.get_ticks_msec() / 1000.0

	# Charger la scène procédurale
	var procedural_scene = load("res://scenes/world/maps/procedural_level.tscn")
	var level_instance = procedural_scene.instantiate()

	# Changer de scène
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(level_instance)
	get_tree().current_scene = level_instance

	# Générer le niveau
	await get_tree().process_frame
	level_instance.generate_level(level)

	current_scene_name = "procedural_level_%d" % level
	scene_changed.emit(current_scene_name)
	level_changed.emit(level)

	print("Niveau ", level, " chargé!")

func complete_level() -> void:
	var completion_time = (Time.get_ticks_msec() / 1000.0) - level_start_time

	var stats = {
		"level": current_level,
		"time": completion_time,
		"enemies_killed": level_enemies_killed,
		"currency_earned": level_currency_earned
	}

	print("=== NIVEAU ", current_level, " TERMINÉ ===")
	print("Temps: ", "%.1f" % completion_time, "s")
	print("Ennemis: ", level_enemies_killed)
	print("K gagnés: ", level_currency_earned)

	level_completed_signal.emit(current_level, stats)

	# Mettre à jour le record
	if current_level >= highest_level_reached:
		highest_level_reached = current_level + 1

	# Passer au niveau suivant après un délai
	current_state = GameState.LEVEL_TRANSITION
	await get_tree().create_timer(2.0).timeout

	current_level += 1
	current_state = GameState.PLAYING

	# Émettre le signal pour que main.gd charge le niveau
	level_changed.emit(current_level)

func on_enemy_killed() -> void:
	level_enemies_killed += 1
	total_enemies_killed += 1

func on_currency_earned(amount: int) -> void:
	level_currency_earned += amount

func get_current_level() -> int:
	return current_level

func get_highest_level() -> int:
	return highest_level_reached
