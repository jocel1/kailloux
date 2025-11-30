extends CharacterBody2D
class_name KaillouNPC
## KaillouNPC - NPC caillou platformer style (side view)

signal state_changed(new_state: KaillouState)
signal talked_to(player: Node)

enum KaillouState { IDLE, SLEEPING, SCARED, TALKING, ANGRY }
enum KaillouType { GALET, SILEX, GRANIT, GEM, GRAVEL }

@export var kaillou_type: KaillouType = KaillouType.GALET
@export var personality: String = "friendly"
@export var dialogue_lines: Array[String] = ["Salut, petit caillou!"]
@export var start_sleeping: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var emote_label: Label = $EmoteLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea

var current_state: KaillouState = KaillouState.IDLE
var health: int = 3
var player_nearby: bool = false
var scared_timer: float = 0.0
var flee_direction: float = 0.0

# Platformer physics
const GRAVITY: float = 600.0
const FLEE_SPEED: float = 100.0
const SCARED_DURATION: float = 3.0

# Sprites pour chaque type de kaillou
const SPRITE_PATHS = {
	KaillouType.GALET: "res://assets/sprites/npcs/kaillou_galet.svg",
	KaillouType.SILEX: "res://assets/sprites/npcs/kaillou_silex.svg",
	KaillouType.GRANIT: "res://assets/sprites/npcs/kaillou_granit.svg",
	KaillouType.GEM: "res://assets/sprites/npcs/kaillou_gem.svg",
	KaillouType.GRAVEL: "res://assets/sprites/npcs/kaillou_gravel.svg",
}

func _ready() -> void:
	add_to_group("npcs")

	if start_sleeping:
		change_state(KaillouState.SLEEPING)

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	_setup_appearance()

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	match current_state:
		KaillouState.IDLE:
			_process_idle(delta)
		KaillouState.SLEEPING:
			_process_sleeping(delta)
		KaillouState.SCARED:
			_process_scared(delta)
		KaillouState.TALKING:
			_process_talking(delta)
		KaillouState.ANGRY:
			_process_angry(delta)

	_update_emote()
	_update_facing()
	move_and_slide()

func _process_idle(_delta: float) -> void:
	velocity.x = 0

func _process_sleeping(_delta: float) -> void:
	velocity.x = 0

func _process_scared(delta: float) -> void:
	scared_timer -= delta
	if scared_timer <= 0:
		change_state(KaillouState.IDLE)
		return

	velocity.x = flee_direction * FLEE_SPEED

func _process_talking(_delta: float) -> void:
	velocity.x = 0

func _process_angry(_delta: float) -> void:
	velocity.x = 0

func _update_emote() -> void:
	match current_state:
		KaillouState.IDLE:
			if player_nearby:
				emote_label.text = "..."
				emote_label.visible = true
				emote_label.modulate = Color(0.7, 0.7, 0.8, 0.8)
			else:
				emote_label.visible = false
		KaillouState.SLEEPING:
			emote_label.text = "zzz"
			emote_label.visible = true
			emote_label.modulate = Color(0.5, 0.5, 0.6, 0.6)
		KaillouState.SCARED:
			emote_label.text = "!"
			emote_label.visible = true
			emote_label.modulate = Color(1, 0.8, 0.3, 1)
		KaillouState.TALKING:
			emote_label.modulate = Color(1, 1, 1, 1)
		KaillouState.ANGRY:
			emote_label.text = "!!"
			emote_label.visible = true
			emote_label.modulate = Color(1, 0.4, 0.4, 1)
		_:
			emote_label.visible = false

func _update_facing() -> void:
	# Face the player if nearby and idle/talking
	if player_nearby and current_state in [KaillouState.IDLE, KaillouState.TALKING]:
		var player = GameManager.get_player()
		if player:
			sprite.flip_h = player.global_position.x < global_position.x

	# Face flee direction when scared
	if current_state == KaillouState.SCARED:
		sprite.flip_h = flee_direction < 0

func _setup_appearance() -> void:
	# Load sprite for kaillou type
	if SPRITE_PATHS.has(kaillou_type):
		var texture = load(SPRITE_PATHS[kaillou_type])
		if texture:
			sprite.texture = texture

	# Adjust scale based on type
	sprite.modulate = Color.WHITE
	match kaillou_type:
		KaillouType.GRANIT:
			sprite.scale = Vector2(1.2, 1.2)
		KaillouType.GRAVEL:
			sprite.scale = Vector2(1.0, 1.0)
		_:
			sprite.scale = Vector2(1.0, 1.0)

func change_state(new_state: KaillouState) -> void:
	current_state = new_state
	state_changed.emit(new_state)

func interact(player: Node) -> void:
	if current_state == KaillouState.SLEEPING:
		# Wake up
		change_state(KaillouState.IDLE)
		return

	if current_state == KaillouState.SCARED:
		return

	change_state(KaillouState.TALKING)
	talked_to.emit(player)

	# Show dialogue
	if not dialogue_lines.is_empty():
		var dialogue = dialogue_lines[randi() % dialogue_lines.size()]
		_show_dialogue(dialogue)

	# Return to idle after delay
	await get_tree().create_timer(2.0).timeout
	if current_state == KaillouState.TALKING:
		change_state(KaillouState.IDLE)

func _show_dialogue(text: String) -> void:
	emote_label.text = text
	emote_label.visible = true

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	health -= amount

	# Visual feedback
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	# Knockback
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * 150
		velocity.y = -100

	if current_state == KaillouState.SLEEPING:
		change_state(KaillouState.SCARED)

	if health <= 0:
		_on_defeated()
		return

	# Flee or get angry based on personality
	if personality == "friendly" or personality == "shy":
		_start_fleeing(knockback_dir)
	else:
		change_state(KaillouState.ANGRY)

func _start_fleeing(from_dir: Vector2) -> void:
	change_state(KaillouState.SCARED)
	scared_timer = SCARED_DURATION

	# Flee in opposite direction of attack
	if from_dir.x != 0:
		flee_direction = -sign(from_dir.x)
	else:
		flee_direction = [-1.0, 1.0][randi() % 2]

func _on_defeated() -> void:
	# NPC rolls away and disappears
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "position:x", position.x + flee_direction * 100, 0.5)
	tween.tween_callback(queue_free)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
