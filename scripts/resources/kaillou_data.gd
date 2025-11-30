extends Resource
class_name KaillouData
## KaillouData - Resource représentant un type de kaillou

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var base_color: Color = Color.WHITE
@export var scale_multiplier: float = 1.0
@export var personality_traits: Array[String] = []
@export var dialogue_style: String = "normal"
@export var base_health: int = 3
@export var movement_speed: float = 100.0

func get_random_trait() -> String:
	if personality_traits.is_empty():
		return "neutral"
	return personality_traits[randi() % personality_traits.size()]
