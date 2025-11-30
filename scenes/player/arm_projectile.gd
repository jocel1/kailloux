extends Area2D
class_name ArmProjectile
## ArmProjectile - Le bras lancé par le joueur comme attaque

@export var speed: float = 400.0
@export var damage: int = 1
@export var lifetime: float = 1.0

const SPRITE_PATH = "res://assets/sprites/player/arm_projectile.svg"

var direction: Vector2 = Vector2.RIGHT
var shooter: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready() -> void:
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start()

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Charger le sprite
	var texture = load(SPRITE_PATH)
	if texture:
		sprite.texture = texture

	# Orienter le sprite dans la direction du tir
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return

	if body.is_in_group("enemies") and body.has_method("take_damage"):
		# Calculer les dégâts avec bonus
		var total_damage = damage + _get_damage_bonus()
		# Passer la direction comme knockback
		body.take_damage(total_damage, direction)
		print("Projectile hit enemy: ", body.name, " (", total_damage, " dmg)")

		# Donner du soul au tireur
		if shooter and shooter.has_method("gain_soul"):
			shooter.gain_soul(10)

		_destroy()

func _get_damage_bonus() -> int:
	if shooter and shooter.has_meta("damage_bonus"):
		return shooter.get_meta("damage_bonus")
	return 0

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent == shooter:
		return

	if parent.is_in_group("enemies") and parent.has_method("take_damage"):
		var total_damage = damage + _get_damage_bonus()
		parent.take_damage(total_damage, direction)
		print("Projectile hit enemy via area: ", parent.name, " (", total_damage, " dmg)")

		if shooter and shooter.has_method("gain_soul"):
			shooter.gain_soul(10)

		_destroy()

func _on_lifetime_timeout() -> void:
	_destroy()

func _destroy() -> void:
	# Petit effet visuel avant de disparaitre
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
