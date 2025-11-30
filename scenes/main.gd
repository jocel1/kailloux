extends Node
## Main - Point d'entrée du jeu

@onready var game_world: Node2D = $GameWorld
@onready var ui: CanvasLayer = $UI

var current_map: Node2D = null

func _ready() -> void:
	# Connecter les signaux du GameManager
	GameManager.scene_changed.connect(_on_scene_changed)
	GameManager.game_paused.connect(_on_game_paused)

	# Demarrer le jeu - Charger le niveau platformer
	_load_map("res://scenes/world/maps/forgotten_caverns.tscn")
	GameManager.current_state = GameManager.GameState.PLAYING

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

func change_map(map_path: String) -> void:
	_load_map(map_path)
