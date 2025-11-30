extends Resource
class_name QuestData
## QuestData - Resource représentant une quête

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var objectives: Array[String] = []
@export var rewards: Array[String] = []
@export var prerequisite_quests: Array[String] = []
@export var auto_start: bool = false

func get_objective_count() -> int:
	return objectives.size()

func get_objective_text(index: int) -> String:
	if index >= 0 and index < objectives.size():
		return objectives[index]
	return ""
