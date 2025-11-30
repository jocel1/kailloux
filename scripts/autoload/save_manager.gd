extends Node
## SaveManager - Gestion des sauvegardes

const SAVE_PATH = "user://save_data.json"

signal game_saved()
signal game_loaded()

func save_game() -> void:
	var save_data = {
		"inventory": {
			"items": InventoryManager.items,
			"unlocked_items": InventoryManager.unlocked_items,
			"equipped_items": InventoryManager.equipped_items
		},
		"quests": {
			"active_quests": QuestManager.active_quests,
			"completed_quests": QuestManager.completed_quests
		},
		"player": {
			"position": _get_player_position(),
			"current_scene": GameManager.current_scene_name
		}
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		game_saved.emit()
		print("Game saved successfully")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Error parsing save file")
		return false

	var save_data = json.get_data()

	# Restore inventory
	if save_data.has("inventory"):
		InventoryManager.items = save_data.inventory.items
		InventoryManager.unlocked_items = Array(save_data.inventory.unlocked_items, TYPE_STRING, "", null)
		InventoryManager.equipped_items = Array(save_data.inventory.equipped_items, TYPE_STRING, "", null)

	# Restore quests
	if save_data.has("quests"):
		QuestManager.active_quests = Array(save_data.quests.active_quests, TYPE_STRING, "", null)
		QuestManager.completed_quests = Array(save_data.quests.completed_quests, TYPE_STRING, "", null)

	game_loaded.emit()
	print("Game loaded successfully")
	return true

func _get_player_position() -> Dictionary:
	var player = GameManager.get_player()
	if player:
		return {"x": player.global_position.x, "y": player.global_position.y}
	return {"x": 0, "y": 0}

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
