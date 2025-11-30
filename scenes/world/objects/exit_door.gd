extends Area2D
class_name ExitDoor
## ExitDoor - Porte de sortie pour passer au niveau suivant

signal level_completed()

@export var auto_activate: bool = true  # Activer automatiquement quand le joueur touche

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_label: Label = $InteractionLabel

var player_in_range: bool = false
var is_activated: bool = false

func _ready() -> void:
	# S'assurer que le monitoring est actif
	monitoring = true
	monitorable = true

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_setup_visual()
	interaction_label.visible = true
	interaction_label.text = ">>> SORTIE >>>"

	print("Exit door créée à position: ", global_position)

func _setup_visual() -> void:
	var texture = load("res://assets/sprites/environment/exit_door.svg")
	if texture:
		sprite.texture = texture

	# Animation de pulsation très visible
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "modulate", Color(0.5, 1.5, 0.5, 1), 0.5)
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 2, 1), 0.5)

func _process(_delta: float) -> void:
	# Fallback: vérifier manuellement si le joueur est proche
	if is_activated:
		return

	var player = GameManager.get_player()
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < 80:
			print("Joueur détecté manuellement à distance: ", distance)
			_activate_exit()

func _input(event: InputEvent) -> void:
	if not player_in_range or is_activated:
		return

	if event.is_action_pressed("interact"):
		_activate_exit()

func _activate_exit() -> void:
	if is_activated:
		return

	is_activated = true
	interaction_label.text = "NIVEAU TERMINE!"

	print("=== PORTE DE SORTIE ACTIVÉE ===")

	# Effet visuel d'activation
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(2, 2), 0.3)
	tween.tween_property(sprite, "modulate", Color(3, 3, 3, 1), 0.2)

	# Notifier le GameManager
	level_completed.emit()
	GameManager.complete_level()

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_activated:
		player_in_range = true
		print("Joueur près de la sortie!")

		# Auto-activation si activé
		if auto_activate:
			_activate_exit()
		else:
			interaction_label.text = "[E] Niveau suivant"

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
