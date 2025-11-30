extends Node
## Main - Point d'entrée du jeu

@onready var game_world: Node2D = $GameWorld
@onready var ui: CanvasLayer = $UI

var current_map: Node2D = null

func _ready() -> void:
	# Connecter les signaux du GameManager
	GameManager.scene_changed.connect(_on_scene_changed)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.level_changed.connect(_on_level_changed)

	# Démarrer le jeu procédural
	_start_procedural_game()

func _start_procedural_game() -> void:
	GameManager.current_state = GameManager.GameState.PLAYING
	_load_procedural_level(1)

func _load_procedural_level(level: int) -> void:
	# Supprimer la map actuelle si elle existe
	if current_map:
		current_map.queue_free()
		await current_map.tree_exited

	# Charger la scène procédurale
	var procedural_scene = load("res://scenes/world/maps/procedural_level.tscn")
	if procedural_scene:
		current_map = procedural_scene.instantiate()
		game_world.add_child(current_map)

		# Attendre que la scène soit prête puis générer le niveau
		await get_tree().process_frame
		if current_map.has_method("generate_level"):
			current_map.generate_level(level)

		GameManager.current_scene_name = "procedural_level_%d" % level
		GameManager.current_level = level

func _load_map(map_path: String) -> void:
	# Supprimer la map actuelle si elle existe
	if current_map:
		current_map.queue_free()
		await current_map.tree_exited

	# Charger la nouvelle map
	var map_scene = load(map_path)
	if map_scene:
		current_map = map_scene.instantiate()
		game_world.add_child(current_map)
		GameManager.current_scene_name = map_path.get_file().get_basename()

func _on_scene_changed(scene_name: String) -> void:
	print("Scene changed to: ", scene_name)

func _on_game_paused(is_paused: bool) -> void:
	# TODO: Afficher le menu pause
	print("Game paused: ", is_paused)

func _on_level_changed(new_level: int) -> void:
	print("=== NIVEAU ", new_level, " ===")
	# Reset les stats du niveau
	GameManager.level_enemies_killed = 0
	GameManager.level_currency_earned = 0
	GameManager.level_start_time = Time.get_ticks_msec() / 1000.0

	# Nouveau seed seulement si c'est un nouveau niveau (pas un restart après mort)
	if GameManager.is_restart:
		print("Restart avec seed: ", GameManager.current_level_seed)
		GameManager.is_restart = false  # Reset le flag
	else:
		GameManager.current_level_seed = randi()
		print("Nouveau seed: ", GameManager.current_level_seed)

	_load_procedural_level(new_level)

func change_map(map_path: String) -> void:
	_load_map(map_path)
