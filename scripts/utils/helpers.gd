extends Node
class_name Helpers
## Helpers - Fonctions utilitaires pour le jeu

static func get_random_direction() -> Vector2:
	var angle = randf() * TAU
	return Vector2(cos(angle), sin(angle))

static func get_direction_to(from: Vector2, to: Vector2) -> Vector2:
	return (to - from).normalized()

static func distance_between(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b)

static func lerp_color(from: Color, to: Color, weight: float) -> Color:
	return from.lerp(to, weight)

static func shake_node(node: Node2D, intensity: float = 5.0, duration: float = 0.3) -> void:
	var original_pos = node.position
	var tween = node.create_tween()

	var shake_count = int(duration * 30)
	for i in range(shake_count):
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(node, "position", original_pos + offset, 0.03)

	tween.tween_property(node, "position", original_pos, 0.03)

static func flash_white(sprite: Sprite2D, duration: float = 0.1) -> void:
	var original_modulate = sprite.modulate
	var tween = sprite.create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE * 2, duration / 2)
	tween.tween_property(sprite, "modulate", original_modulate, duration / 2)

static func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

static func clamp_to_rect(position: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clamp(position.x, rect.position.x, rect.position.x + rect.size.x),
		clamp(position.y, rect.position.y, rect.position.y + rect.size.y)
	)
