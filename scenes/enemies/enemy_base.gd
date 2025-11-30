extends CharacterBody2D
class_name EnemyBase
## EnemyBase - Ennemi basique qui patrouille et attaque

signal died()
signal hit_player(damage: int)

@export var max_health: int = 2
@export var damage: int = 1
@export var speed: float = 60.0
@export var detection_range: float = 150.0
@export var patrol_distance: float = 100.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var hitbox: Area2D = $Hitbox

const GRAVITY: float = 800.0
const KNOCKBACK_FORCE: float = 200.0

var health: int
var patrol_direction: float = 1.0
var start_position: Vector2
var player_detected: bool = false
var player_ref: Node = null
var is_dead: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	start_position = global_position

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	hitbox.body_entered.connect(_on_hitbox_body_entered)

	_load_sprite()

func _load_sprite() -> void:
	var texture = load("res://assets/sprites/enemies/enemy_crawler.svg")
	if texture:
		sprite.texture = texture
	else:
		# Fallback: create colored placeholder
		sprite.modulate = Color(0.4, 0.15, 0.15, 1)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Stun recovery
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
		velocity.x = move_toward(velocity.x, 0, speed * delta * 5)
		move_and_slide()
		return

	# Behavior
	if player_detected and player_ref:
		_chase_player(delta)
	else:
		_patrol(delta)

	_update_sprite()
	move_and_slide()

func _patrol(_delta: float) -> void:
	# Check patrol bounds
	var distance_from_start = global_position.x - start_position.x

	if abs(distance_from_start) > patrol_distance:
		patrol_direction = -sign(distance_from_start)

	# Check for walls/edges
	if is_on_wall():
		patrol_direction *= -1

	velocity.x = patrol_direction * speed

func _chase_player(_delta: float) -> void:
	if player_ref:
		var direction = sign(player_ref.global_position.x - global_position.x)
		velocity.x = direction * speed * 1.5

func _update_sprite() -> void:
	sprite.flip_h = velocity.x < 0

	# Stun visual
	if is_stunned:
		sprite.modulate = Color(1, 0.5, 0.5, 1)
	else:
		sprite.modulate = Color.WHITE

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	health -= amount
	is_stunned = true
	stun_timer = 0.3

	# Knockback
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * KNOCKBACK_FORCE
	velocity.y = -100

	# Flash effect - bright flash then red tint
	var tween = create_tween()
	sprite.modulate = Color(3, 3, 3, 1)  # Bright flash
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 1), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

	print("Enemy hit! Health remaining: ", health)

	if health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	died.emit()

	# Death animation
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.5, 0.3), 0.2)
	tween.tween_callback(queue_free)

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		player_detected = true
		player_ref = body

func _on_detection_body_exited(body: Node2D) -> void:
	if body is Player:
		player_detected = false
		player_ref = null

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player and not is_dead and not is_stunned:
		var knockback_dir = (body.global_position - global_position).normalized()
		body.take_damage(damage, knockback_dir)
		hit_player.emit(damage)
