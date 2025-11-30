extends Node
## QuestManager - Gestion des quêtes

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_objective_completed(quest_id: String, objective_index: int)
signal quest_updated(quest_id: String)

var quests_data: Dictionary = {}  # Loaded from JSON
var active_quests: Array[String] = []
var completed_quests: Array[String] = []
var quest_progress: Dictionary = {}  # quest_id -> {objectives: [bool, bool, ...]}

func _ready() -> void:
	_load_quests_data()

func _load_quests_data() -> void:
	var file_path = "res://data/quests.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			file.close()
			if parse_result == OK:
				quests_data = json.get_data()

func start_quest(quest_id: String) -> bool:
	if quest_id in active_quests or quest_id in completed_quests:
		return false

	if not quests_data.has(quest_id):
		print("Quest not found: ", quest_id)
		return false

	active_quests.append(quest_id)
	var quest = quests_data[quest_id]
	var objectives_count = quest.get("objectives", []).size()
	quest_progress[quest_id] = {
		"objectives": []
	}
	for i in range(objectives_count):
		quest_progress[quest_id].objectives.append(false)

	quest_started.emit(quest_id)
	return true

func complete_objective(quest_id: String, objective_index: int) -> void:
	if quest_id not in active_quests:
		return

	if not quest_progress.has(quest_id):
		return

	if objective_index < quest_progress[quest_id].objectives.size():
		quest_progress[quest_id].objectives[objective_index] = true
		quest_objective_completed.emit(quest_id, objective_index)
		quest_updated.emit(quest_id)
		_check_quest_completion(quest_id)

func _check_quest_completion(quest_id: String) -> void:
	if not quest_progress.has(quest_id):
		return

	var all_completed = true
	for obj_complete in quest_progress[quest_id].objectives:
		if not obj_complete:
			all_completed = false
			break

	if all_completed:
		_complete_quest(quest_id)

func _complete_quest(quest_id: String) -> void:
	if quest_id not in active_quests:
		return

	active_quests.erase(quest_id)
	completed_quests.append(quest_id)

	# Give rewards
	if quests_data.has(quest_id):
		var quest = quests_data[quest_id]
		for reward in quest.get("rewards", []):
			InventoryManager.unlock_item(reward)

	quest_completed.emit(quest_id)

func is_quest_active(quest_id: String) -> bool:
	return quest_id in active_quests

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

func get_quest_data(quest_id: String) -> Dictionary:
	return quests_data.get(quest_id, {})

func get_active_quests() -> Array[String]:
	return active_quests.duplicate()

func get_quest_progress(quest_id: String) -> Dictionary:
	return quest_progress.get(quest_id, {})
