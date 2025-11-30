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

	if body.has_method("take_damage"):
		body.take_damage(damage, shooter)

	if body.has_method("on_hit"):
		body.on_hit(self)

	_destroy()

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent == shooter:
		return

	if parent.has_method("take_damage"):
		parent.take_damage(damage, shooter)

	if parent.has_method("on_hit"):
		parent.on_hit(self)

func _on_lifetime_timeout() -> void:
	_destroy()

func _destroy() -> void:
	queue_free()
