extends CharacterBody2D
class_name Player
## Player - Controleur du kaillou joueur (style Hollow Knight)

signal attacked(direction: Vector2)
signal damaged(amount: int)
signal healed(amount: int)
signal died()
signal interacted(target: Node)

# Movement constants
const SPEED: float = 200.0
const JUMP_VELOCITY: float = -500.0
const GRAVITY: float = 800.0
const COYOTE_TIME: float = 0.1
const JUMP_BUFFER_TIME: float = 0.1
const WALL_SLIDE_SPEED: float = 100.0

# Dash constants
const DASH_SPEED: float = 400.0
const DASH_DURATION: float = 0.15
const DASH_COOLDOWN: float = 0.5

# Attack constants
const ATTACK_COOLDOWN: float = 0.3
const ATTACK_RANGE: float = 35.0
const POGO_VELOCITY: float = -400.0

# Health
const MAX_HEALTH: int = 5
const INVINCIBILITY_TIME: float = 1.0
const DEATH_Y_THRESHOLD: float = 1000.0  # Fall death

# Sprite paths
const SPRITE_NORMAL = "res://assets/sprites/player/kaillou_player.svg"
const SPRITE_CANDLE = "res://assets/sprites/player/kaillou_player_candle.svg"

# Exports
@export var has_candle: bool = false
@export var has_double_jump: bool = false
@export var has_dash: bool = true
@export var has_wall_jump: bool = false

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_area: Area2D = $InteractionArea
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var invincibility_timer: Timer = $InvincibilityTimer

# State
var facing_direction: int = 1  # 1 = right, -1 = left
var can_attack: bool = true
var can_dash: bool = true
var is_dashing: bool = false
var is_invincible: bool = false
var has_coyote: bool = false
var has_jump_buffer: bool = false
var can_double_jump: bool = false
var is_wall_sliding: bool = false
var current_health: int = MAX_HEALTH
var soul: float = 0.0
var interactable_objects: Array[Node] = []

# Attack state
var attack_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false


func _ready() -> void:
	GameManager.register_player(self)
	_setup_timers()
	_setup_signals()
	_load_player_sprite()
	attack_hitbox.monitoring = false


func _setup_timers() -> void:
	coyote_timer.wait_time = COYOTE_TIME
	coyote_timer.one_shot = true

	jump_buffer_timer.wait_time = JUMP_BUFFER_TIME
	jump_buffer_timer.one_shot = true

	dash_timer.wait_time = DASH_DURATION
	dash_timer.one_shot = true

	dash_cooldown_timer.wait_time = DASH_COOLDOWN
	dash_cooldown_timer.one_shot = true

	attack_cooldown_timer.wait_time = ATTACK_COOLDOWN
	attack_cooldown_timer.one_shot = true

	invincibility_timer.wait_time = INVINCIBILITY_TIME
	invincibility_timer.one_shot = true


func _setup_signals() -> void:
	coyote_timer.timeout.connect(_on_coyote_timeout)
	jump_buffer_timer.timeout.connect(_on_jump_buffer_timeout)
	dash_timer.timeout.connect(_on_dash_timeout)
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	invincibility_timer.timeout.connect(_on_invincibility_timeout)

	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	interaction_area.area_entered.connect(_on_interaction_area_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_area_exited)

	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)


func _load_player_sprite() -> void:
	var sprite_path = SPRITE_CANDLE if has_candle else SPRITE_NORMAL
	var texture = load(sprite_path)
	if texture:
		sprite.texture = texture


func set_candle(enabled: bool) -> void:
	has_candle = enabled
	_load_player_sprite()


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	# Check for fall death
	if global_position.y > DEATH_Y_THRESHOLD:
		die()
		return

	_handle_gravity(delta)
	_handle_coyote_time()
	_handle_wall_slide()
	_handle_jump()
	_handle_dash()
	_handle_horizontal_movement()
	_handle_attack_input()
	_update_sprite()

	move_and_slide()


func _handle_gravity(delta: float) -> void:
	if is_dashing:
		return

	if not is_on_floor():
		if is_wall_sliding:
			velocity.y = min(velocity.y + GRAVITY * delta, WALL_SLIDE_SPEED)
		else:
			velocity.y += GRAVITY * delta
	else:
		can_double_jump = has_double_jump


func _handle_coyote_time() -> void:
	if is_on_floor():
		has_coyote = true
		coyote_timer.stop()
	elif has_coyote and coyote_timer.is_stopped():
		coyote_timer.start()


func _handle_wall_slide() -> void:
	if not has_wall_jump:
		is_wall_sliding = false
		return

	var on_wall = is_on_wall_only()
	var moving_into_wall = (Input.is_action_pressed("move_left") and facing_direction == -1) or \
						   (Input.is_action_pressed("move_right") and facing_direction == 1)

	is_wall_sliding = on_wall and not is_on_floor() and moving_into_wall and velocity.y > 0


func _handle_jump() -> void:
	# Buffer jump input
	if Input.is_action_just_pressed("jump"):
		has_jump_buffer = true
		jump_buffer_timer.start()

	# Execute jump
	if has_jump_buffer:
		# Wall jump
		if is_wall_sliding and has_wall_jump:
			velocity.y = JUMP_VELOCITY
			velocity.x = -facing_direction * SPEED * 1.2
			facing_direction = -facing_direction
			has_jump_buffer = false
			is_wall_sliding = false
		# Normal jump (with coyote time)
		elif has_coyote:
			velocity.y = JUMP_VELOCITY
			has_coyote = false
			has_jump_buffer = false
		# Double jump
		elif can_double_jump:
			velocity.y = JUMP_VELOCITY
			can_double_jump = false
			has_jump_buffer = false

	# Variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5


func _handle_dash() -> void:
	if Input.is_action_just_pressed("dash") and can_dash and has_dash:
		_start_dash()


func _start_dash() -> void:
	is_dashing = true
	can_dash = false
	is_invincible = true

	# Dash direction
	var dash_dir = Vector2(facing_direction, 0)

	# Allow 8-direction dash with input
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input_dir != Vector2.ZERO:
		dash_dir = input_dir.normalized()

	velocity = dash_dir * DASH_SPEED

	dash_timer.start()
	# Visual effect
	sprite.modulate = Color(1, 1, 1, 0.5)


func _handle_horizontal_movement() -> void:
	if is_dashing:
		return

	var direction = Input.get_axis("move_left", "move_right")

	if direction != 0:
		velocity.x = direction * SPEED
		facing_direction = int(sign(direction))
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.3)


func _handle_attack_input() -> void:
	if Input.is_action_just_pressed("attack"):
		attack()

	if Input.is_action_just_pressed("interact"):
		interact()


func attack() -> void:
	if not can_attack or is_attacking:
		return

	is_attacking = true
	can_attack = false
	attack_cooldown_timer.start()

	# Determine attack direction
	if Input.is_action_pressed("move_up"):
		attack_direction = Vector2.UP
	elif Input.is_action_pressed("move_down") and not is_on_floor():
		attack_direction = Vector2.DOWN
	else:
		attack_direction = Vector2(facing_direction, 0)

	# Position attack hitbox
	attack_hitbox.position = attack_direction * ATTACK_RANGE
	attack_hitbox.monitoring = true

	# Force physics update and check for already-overlapping bodies
	await get_tree().physics_frame
	_check_attack_hits()

	# Play animation
	_play_attack_animation()

	attacked.emit(attack_direction)

	# Disable hitbox after short time
	await get_tree().create_timer(0.15).timeout
	attack_hitbox.monitoring = false
	is_attacking = false


func _check_attack_hits() -> void:
	var hit_something = false

	# Check bodies (CharacterBody2D enemies)
	var bodies = attack_hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			print("Hit enemy body: ", body.name)
			body.take_damage(1, attack_direction)
			gain_soul(10)
			hit_something = true
			# Pogo bounce on downward attack
			if attack_direction == Vector2.DOWN:
				velocity.y = POGO_VELOCITY

	# Check areas (Area2D hitboxes)
	var areas = attack_hitbox.get_overlapping_areas()
	for area in areas:
		var parent = area.get_parent()
		if parent.is_in_group("enemies") and parent.has_method("take_damage"):
			print("Hit enemy via area: ", parent.name)
			parent.take_damage(1, attack_direction)
			gain_soul(10)
			hit_something = true
			if attack_direction == Vector2.DOWN:
				velocity.y = POGO_VELOCITY

	if not hit_something and (bodies.size() > 0 or areas.size() > 0):
		print("Attack overlapped with: ", bodies.size(), " bodies, ", areas.size(), " areas but none were enemies")


func _play_attack_animation() -> void:
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")

	# Visual feedback - flash white then back
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5, 1), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	# Slight screen shake effect via camera
	var camera = get_node_or_null("Camera2D")
	if camera:
		var original_offset = camera.offset
		camera.offset = original_offset + attack_direction * 3
		await get_tree().create_timer(0.05).timeout
		camera.offset = original_offset


func interact() -> void:
	if interactable_objects.is_empty():
		return

	var closest: Node = null
	var closest_distance: float = INF

	for obj in interactable_objects:
		if obj.has_method("interact"):
			var distance = global_position.distance_to(obj.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest = obj

	if closest:
		closest.interact(self)
		interacted.emit(closest)


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_invincible:
		return

	current_health -= amount
	is_invincible = true
	invincibility_timer.start()

	# Knockback
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * 200
	velocity.y = -150

	# Visual feedback
	sprite.modulate = Color(1, 0.3, 0.3, 1)

	damaged.emit(amount)

	if current_health <= 0:
		die()


func heal(amount: int) -> void:
	current_health = min(current_health + amount, MAX_HEALTH)
	healed.emit(amount)


func gain_soul(amount: float) -> void:
	soul = min(soul + amount, 100.0)


func die() -> void:
	died.emit()
	# Respawn at checkpoint
	GameManager.respawn_player()


func _update_sprite() -> void:
	# Flip based on facing direction
	sprite.flip_h = facing_direction < 0

	# Update animation based on state
	if is_dashing:
		pass  # Keep dash visual
	elif is_wall_sliding:
		pass  # Wall slide animation
	elif not is_on_floor():
		if velocity.y < 0:
			pass  # Jump animation
		else:
			pass  # Fall animation
	elif abs(velocity.x) > 10:
		pass  # Run animation
	else:
		pass  # Idle animation


# Timer callbacks
func _on_coyote_timeout() -> void:
	has_coyote = false


func _on_jump_buffer_timeout() -> void:
	has_jump_buffer = false


func _on_dash_timeout() -> void:
	is_dashing = false
	is_invincible = false
	sprite.modulate = Color.WHITE
	velocity = velocity * 0.5
	dash_cooldown_timer.start()


func _on_dash_cooldown_timeout() -> void:
	can_dash = true


func _on_attack_cooldown_timeout() -> void:
	can_attack = true


func _on_invincibility_timeout() -> void:
	is_invincible = false
	sprite.modulate = Color.WHITE


# Interaction callbacks
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.has_method("interact") and body not in interactable_objects:
		interactable_objects.append(body)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body in interactable_objects:
		interactable_objects.erase(body)


func _on_interaction_area_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	# Exclude self and own children
	if parent == self or parent.get_parent() == self:
		return
	if parent.has_method("interact") and parent not in interactable_objects:
		interactable_objects.append(parent)


func _on_interaction_area_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent in interactable_objects:
		interactable_objects.erase(parent)


# Attack hitbox callbacks
func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(1, attack_direction)
		gain_soul(10)

		# Pogo bounce
		if attack_direction == Vector2.DOWN:
			velocity.y = POGO_VELOCITY


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.is_in_group("enemies") and parent.has_method("take_damage"):
		parent.take_damage(1, attack_direction)
		gain_soul(10)

		# Pogo bounce
		if attack_direction == Vector2.DOWN:
			velocity.y = POGO_VELOCITY
