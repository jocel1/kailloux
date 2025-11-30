extends Node2D
class_name ProceduralMapGenerator
## ProceduralMapGenerator - Génère des niveaux platformer de manière procédurale

signal generation_complete()

# Constantes physiques (basées sur player.gd)
const MAX_JUMP_HEIGHT: float = 130.0  # Marge de sécurité sur 156px théorique
const MAX_JUMP_DISTANCE: float = 200.0  # Marge de sécurité sur 250px théorique
const MIN_PLATFORM_WIDTH: float = 150.0  # Augmenté pour des plateformes plus larges
const MAX_PLATFORM_WIDTH: float = 350.0  # Augmenté

# Progression par niveau
const BASE_MAP_WIDTH: float = 3000.0
const MAP_WIDTH_INCREMENT: float = 500.0
const BASE_ENEMY_DENSITY: float = 400.0
const ENEMY_DENSITY_MULTIPLIER: float = 0.85
const BASE_ENEMY_SPEED: float = 60.0
const ENEMY_SPEED_INCREMENT: float = 10.0

# Paramètres de génération
const FLOOR_Y: float = 450.0
const MAP_HEIGHT: float = 600.0
const SHOP_INTERVAL: float = 800.0
const COLUMN_WIDTH: float = 300.0

# Scènes préchargées
var PlatformScene = preload("res://scenes/world/objects/platform.tscn")
var ChestScene = preload("res://scenes/world/objects/chest.tscn")
var ShopScene = preload("res://scenes/world/objects/shop.tscn")
var ExitDoorScene = preload("res://scenes/world/objects/exit_door.tscn")
var EnemyScene = preload("res://scenes/enemies/enemy_base.tscn")
var PlayerScene = preload("res://scenes/player/player.tscn")

# Paramètres du niveau actuel
@export var current_level: int = 1
@export var seed_value: int = -1

# Conteneurs
var ground_container: Node2D
var platforms_container: Node2D
var enemies_container: Node2D
var chests_container: Node2D
var decorations_container: Node2D

# Données générées
var ground_segments: Array[Dictionary] = []  # {x, width, is_gap}
var platforms: Array[Dictionary] = []  # {x, y, width}

func _ready() -> void:
	pass  # Le seed est géré dans generate_level()

func generate_level(level: int = 1) -> void:
	current_level = level
	_clear_level()
	_setup_containers()

	# Utiliser le seed du GameManager pour régénérer la même map
	seed(GameManager.current_level_seed)

	var params = _get_level_params(level)
	var map_width = params.map_width

	print("Génération niveau ", level, " - Largeur: ", map_width, "px - Seed: ", GameManager.current_level_seed)

	# Étape 1: Générer le sol avec trous
	_generate_ground(map_width)

	# Étape 2: Générer les plateformes
	_generate_platforms(map_width)

	# Étape 3: Placer les shops
	_place_shops(map_width)

	# Étape 4: Placer les ennemis
	_place_enemies(map_width, params.enemy_density, params.enemy_speed)

	# Étape 5: Placer les coffres (basé sur hauteur)
	_place_chests()

	# Étape 6: Placer la porte de sortie
	_place_exit_door(map_width)

	# Étape 7: Spawner le joueur
	_spawn_player()

	# Étape 8: Créer les murs et le fond
	_create_boundaries(map_width)
	_create_background(map_width)

	# Étape 9: Décorations
	_add_decorations(map_width)

	generation_complete.emit()
	print("Niveau ", level, " généré!")

func _get_level_params(level: int) -> Dictionary:
	return {
		"map_width": BASE_MAP_WIDTH + (level - 1) * MAP_WIDTH_INCREMENT,
		"enemy_density": BASE_ENEMY_DENSITY * pow(ENEMY_DENSITY_MULTIPLIER, level - 1),
		"enemy_speed": BASE_ENEMY_SPEED + (level - 1) * ENEMY_SPEED_INCREMENT
	}

func _clear_level() -> void:
	for child in get_children():
		child.queue_free()
	ground_segments.clear()
	platforms.clear()

func _setup_containers() -> void:
	ground_container = Node2D.new()
	ground_container.name = "Ground"
	add_child(ground_container)

	platforms_container = Node2D.new()
	platforms_container.name = "Platforms"
	add_child(platforms_container)

	enemies_container = Node2D.new()
	enemies_container.name = "Enemies"
	add_child(enemies_container)

	chests_container = Node2D.new()
	chests_container.name = "Chests"
	add_child(chests_container)

	decorations_container = Node2D.new()
	decorations_container.name = "Decorations"
	decorations_container.z_index = -2
	add_child(decorations_container)

func _generate_ground(map_width: float) -> void:
	var x: float = 0.0

	# Toujours commencer par du sol solide pour le spawn
	var start_segment = {"x": 0, "width": 300.0, "is_gap": false}
	ground_segments.append(start_segment)
	_create_ground_segment(start_segment)
	x = 300.0

	while x < map_width - 300:  # Garder de la place pour la fin
		var roll = randf()

		if roll < 0.70:
			# Sol normal (70%)
			var width = randf_range(100, 300)
			width = min(width, map_width - x - 200)
			var segment = {"x": x, "width": width, "is_gap": false}
			ground_segments.append(segment)
			_create_ground_segment(segment)
			x += width
		else:
			# Trou (30%) - max MAX_JUMP_DISTANCE
			var gap_width = randf_range(80, min(180, MAX_JUMP_DISTANCE))
			var segment = {"x": x, "width": gap_width, "is_gap": true}
			ground_segments.append(segment)
			x += gap_width

	# Segment final pour la porte de sortie
	var end_segment = {"x": x, "width": map_width - x, "is_gap": false}
	ground_segments.append(end_segment)
	_create_ground_segment(end_segment)

func _create_ground_segment(segment: Dictionary) -> void:
	if segment.is_gap:
		return

	var ground = StaticBody2D.new()
	ground.position = Vector2(segment.x + segment.width / 2, FLOOR_Y)
	ground.collision_layer = 4
	ground.collision_mask = 0

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(segment.width, 32)
	collision.shape = shape
	ground.add_child(collision)

	# Visuel
	var visual = ColorRect.new()
	visual.size = Vector2(segment.width, 200)
	visual.position = Vector2(-segment.width / 2, -16)
	visual.color = Color(0.2, 0.22, 0.25, 1)
	ground.add_child(visual)

	var top_line = ColorRect.new()
	top_line.size = Vector2(segment.width, 4)
	top_line.position = Vector2(-segment.width / 2, -16)
	top_line.color = Color(0.35, 0.4, 0.45, 1)
	ground.add_child(top_line)

	ground_container.add_child(ground)

func _generate_platforms(map_width: float) -> void:
	var num_columns = int(map_width / COLUMN_WIDTH)
	var min_platforms = max(5, int(map_width / 500))  # Au moins 5 plateformes, ou 1 par 500px

	# Générer des plateformes garanties d'abord
	for i in range(min_platforms):
		var platform_x = 200 + (i * (map_width - 400) / min_platforms) + randf_range(-50, 50)
		# Alterner les hauteurs pour varier
		var platform_y: float
		if i % 3 == 0:
			platform_y = FLOOR_Y - 100  # Basse
		elif i % 3 == 1:
			platform_y = FLOOR_Y - 180  # Moyenne
		else:
			platform_y = FLOOR_Y - 250  # Haute

		var platform_width = randf_range(MIN_PLATFORM_WIDTH, MAX_PLATFORM_WIDTH)
		var platform_data = {"x": platform_x, "y": platform_y, "width": platform_width}
		platforms.append(platform_data)
		_create_platform(platform_data)

	# Ajouter quelques plateformes supplémentaires aléatoires
	for col in range(num_columns):
		var col_x = col * COLUMN_WIDTH + COLUMN_WIDTH / 2

		# 30% de chance d'ajouter une plateforme bonus
		if randf() < 0.3:
			var platform_y = randf_range(FLOOR_Y - 280, FLOOR_Y - 80)
			var platform_width = randf_range(MIN_PLATFORM_WIDTH, MAX_PLATFORM_WIDTH)
			var platform_x = col_x + randf_range(-80, 80)

			# Vérifier qu'on ne chevauche pas une plateforme existante
			var too_close = false
			for existing in platforms:
				if abs(existing.x - platform_x) < 150 and abs(existing.y - platform_y) < 60:
					too_close = true
					break

			if not too_close:
				var platform_data = {"x": platform_x, "y": platform_y, "width": platform_width}
				platforms.append(platform_data)
				_create_platform(platform_data)

func _is_platform_accessible(px: float, py: float) -> bool:
	# Vérifier si accessible depuis le sol
	for segment in ground_segments:
		if segment.is_gap:
			continue
		var ground_center_x = segment.x + segment.width / 2
		var dx = abs(px - ground_center_x)
		var dy = FLOOR_Y - py

		if dy <= MAX_JUMP_HEIGHT and dx <= MAX_JUMP_DISTANCE + segment.width / 2:
			return true

	# Vérifier si accessible depuis une autre plateforme
	for platform in platforms:
		var dx = abs(px - platform.x)
		var dy = platform.y - py  # positif si on monte

		if dy <= MAX_JUMP_HEIGHT and dy >= -MAX_JUMP_HEIGHT and dx <= MAX_JUMP_DISTANCE:
			return true

	return false

func _create_platform(platform_data: Dictionary) -> void:
	var platform = StaticBody2D.new()
	platform.position = Vector2(platform_data.x, platform_data.y)
	platform.collision_layer = 4
	platform.collision_mask = 0

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(platform_data.width, 32)
	collision.shape = shape
	platform.add_child(collision)

	# Visuel
	var visual = ColorRect.new()
	visual.size = Vector2(platform_data.width, 32)
	visual.position = Vector2(-platform_data.width / 2, -16)
	visual.color = Color(0.25, 0.28, 0.32, 1)
	platform.add_child(visual)

	var top_line = ColorRect.new()
	top_line.size = Vector2(platform_data.width, 4)
	top_line.position = Vector2(-platform_data.width / 2, -16)
	top_line.color = Color(0.4, 0.45, 0.5, 1)
	platform.add_child(top_line)

	platforms_container.add_child(platform)

func _place_shops(map_width: float) -> void:
	# Un seul shop au sol, vers la fin (à 80% de la map)
	var end_x = map_width * 0.8
	var ground_pos = _find_ground_position_near(end_x)
	if ground_pos != Vector2.ZERO:
		var shop = ShopScene.instantiate()
		shop.position = ground_pos
		add_child(shop)
		print("Shop placé à: ", ground_pos)

func _find_platform_near(target_x: float) -> Vector2:
	var best_platform: Dictionary = {}
	var best_distance = INF

	for platform in platforms:
		var dist = abs(platform.x - target_x)
		if dist < best_distance and dist < 200:
			best_distance = dist
			best_platform = platform

	if best_platform.is_empty():
		return Vector2.ZERO

	return Vector2(best_platform.x, best_platform.y - 16)

func _find_ground_position_near(target_x: float) -> Vector2:
	for segment in ground_segments:
		if segment.is_gap:
			continue
		if target_x >= segment.x and target_x <= segment.x + segment.width:
			return Vector2(target_x, FLOOR_Y - 16)

	# Chercher le segment le plus proche
	for segment in ground_segments:
		if segment.is_gap:
			continue
		var seg_center = segment.x + segment.width / 2
		if abs(seg_center - target_x) < 300:
			return Vector2(seg_center, FLOOR_Y - 16)

	return Vector2.ZERO

func _find_valid_position_near(target_x: float) -> Vector2:
	# Chercher sur le sol
	for segment in ground_segments:
		if segment.is_gap:
			continue
		if target_x >= segment.x and target_x <= segment.x + segment.width:
			return Vector2(target_x, FLOOR_Y - 16)

	# Chercher sur une plateforme
	for platform in platforms:
		if abs(platform.x - target_x) < 150:
			return Vector2(platform.x, platform.y - 16)

	# Chercher le sol le plus proche
	var closest_x = target_x
	for segment in ground_segments:
		if segment.is_gap:
			continue
		var seg_center = segment.x + segment.width / 2
		if abs(seg_center - target_x) < abs(closest_x - target_x):
			closest_x = seg_center

	return Vector2(closest_x, FLOOR_Y - 16)

func _place_enemies(map_width: float, density: float, enemy_speed: float) -> void:
	var num_enemies = int(map_width / density)

	for i in range(num_enemies):
		var x = randf_range(400, map_width - 200)  # Éviter le spawn et la sortie

		# Position sur sol ou plateforme
		var pos = _find_valid_position_near(x)
		if pos != Vector2.ZERO:
			var enemy = EnemyScene.instantiate()
			enemy.position = pos
			enemy.speed = enemy_speed
			enemy.patrol_distance = randf_range(60, 120)
			enemies_container.add_child(enemy)

func _place_chests() -> void:
	# Placer des coffres sur les plateformes selon leur hauteur
	for platform in platforms:
		var spawn_chance = _get_chest_spawn_chance(platform.y)

		if randf() < spawn_chance:
			var chest = ChestScene.instantiate()
			chest.position = Vector2(platform.x, platform.y - 32)

			# Déterminer le type et la récompense
			var chest_type = _get_chest_type()
			var reward = _get_chest_reward(chest_type, platform.y)

			match chest_type:
				"normal":
					chest.content_item_id = "currency_%d" % reward
					chest.currency_amount = reward
				"gem":
					chest.content_item_id = "gem_%d" % reward
					chest.currency_amount = reward
					chest.is_gem_chest = true
				"trap":
					chest.is_trap = true

			chests_container.add_child(chest)

	# Quelques coffres au sol (5% de chance par segment)
	for segment in ground_segments:
		if segment.is_gap:
			continue
		if randf() < 0.05:
			var chest = ChestScene.instantiate()
			chest.position = Vector2(segment.x + segment.width / 2, FLOOR_Y - 32)
			var reward = _get_chest_reward("normal", FLOOR_Y)
			chest.currency_amount = reward
			chests_container.add_child(chest)

func _get_chest_spawn_chance(platform_y: float) -> float:
	var height_above_floor = FLOOR_Y - platform_y

	if height_above_floor < 50:
		return 0.05  # Sol: 5%
	elif height_above_floor < 150:
		return 0.15  # Bas: 15%
	elif height_above_floor < 250:
		return 0.30  # Moyen: 30%
	else:
		return 0.50  # Haut: 50%

func _get_chest_type() -> String:
	var roll = randf()
	if roll < 0.60:
		return "normal"
	elif roll < 0.85:
		return "gem"
	else:
		return "trap"

func _get_chest_reward(chest_type: String, platform_y: float) -> int:
	var base_reward = 50
	var height_multiplier = 1.0 + (FLOOR_Y - platform_y) / 200.0

	match chest_type:
		"normal":
			return int(base_reward * height_multiplier)
		"gem":
			return int(base_reward * height_multiplier * 3)
		"trap":
			return 0
	return 0

func _place_exit_door(map_width: float) -> void:
	var exit = ExitDoorScene.instantiate()
	exit.position = Vector2(map_width - 100, FLOOR_Y - 16)
	add_child(exit)

func _spawn_player() -> void:
	var player = PlayerScene.instantiate()
	player.position = Vector2(100, FLOOR_Y - 50)
	add_child(player)

func _create_boundaries(map_width: float) -> void:
	# Mur gauche
	var wall_left = StaticBody2D.new()
	wall_left.position = Vector2(-16, 200)
	wall_left.collision_layer = 4
	wall_left.collision_mask = 0

	var shape_left = CollisionShape2D.new()
	var rect_left = RectangleShape2D.new()
	rect_left.size = Vector2(32, 800)
	shape_left.shape = rect_left
	wall_left.add_child(shape_left)

	var visual_left = ColorRect.new()
	visual_left.size = Vector2(32, 800)
	visual_left.position = Vector2(-16, -400)
	visual_left.color = Color(0.15, 0.16, 0.18, 1)
	wall_left.add_child(visual_left)

	add_child(wall_left)

	# Mur droit
	var wall_right = StaticBody2D.new()
	wall_right.position = Vector2(map_width + 16, 200)
	wall_right.collision_layer = 4
	wall_right.collision_mask = 0

	var shape_right = CollisionShape2D.new()
	var rect_right = RectangleShape2D.new()
	rect_right.size = Vector2(32, 800)
	shape_right.shape = rect_right
	wall_right.add_child(shape_right)

	var visual_right = ColorRect.new()
	visual_right.size = Vector2(32, 800)
	visual_right.position = Vector2(-16, -400)
	visual_right.color = Color(0.15, 0.16, 0.18, 1)
	wall_right.add_child(visual_right)

	add_child(wall_right)

func _create_background(map_width: float) -> void:
	var bg = ColorRect.new()
	bg.z_index = -10
	bg.size = Vector2(map_width + 200, MAP_HEIGHT + 400)
	bg.position = Vector2(-100, -200)
	bg.color = Color(0.08, 0.1, 0.14, 1)
	add_child(bg)

	# Quelques zones de lumière
	for i in range(int(map_width / 600)):
		var glow = ColorRect.new()
		glow.z_index = -8
		glow.size = Vector2(randf_range(200, 400), randf_range(150, 300))
		glow.position = Vector2(randf_range(0, map_width), randf_range(50, 300))
		glow.color = Color(randf_range(0.1, 0.2), randf_range(0.1, 0.2), randf_range(0.2, 0.3), 0.3)
		add_child(glow)

func _add_decorations(map_width: float) -> void:
	# Stalactites en haut
	var num_stalactites = int(map_width / 200)
	for _i in range(num_stalactites):
		var stalactite = ColorRect.new()
		stalactite.size = Vector2(randf_range(15, 30), randf_range(40, 100))
		stalactite.position = Vector2(randf_range(0, map_width), -50)
		stalactite.color = Color(0.28, 0.3, 0.33, 1)
		decorations_container.add_child(stalactite)
