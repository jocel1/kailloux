extends Node
## InventoryManager - Gestion de l'inventaire du joueur

signal item_added(item_id: String)
signal item_removed(item_id: String)
signal item_unlocked(item_id: String)
signal inventory_changed()

var items: Dictionary = {}  # item_id -> quantity
var unlocked_items: Array[String] = []
var equipped_items: Array[String] = ["", "", ""]  # 3 slots pour les touches 1, 2, 3

func _ready() -> void:
	_init_default_items()

func _init_default_items() -> void:
	pass

func add_item(item_id: String, quantity: int = 1) -> void:
	if items.has(item_id):
		items[item_id] += quantity
	else:
		items[item_id] = quantity
	item_added.emit(item_id)
	inventory_changed.emit()

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not items.has(item_id) or items[item_id] < quantity:
		return false
	items[item_id] -= quantity
	if items[item_id] <= 0:
		items.erase(item_id)
	item_removed.emit(item_id)
	inventory_changed.emit()
	return true

func has_item(item_id: String, quantity: int = 1) -> bool:
	return items.has(item_id) and items[item_id] >= quantity

func get_item_count(item_id: String) -> int:
	return items.get(item_id, 0)

func unlock_item(item_id: String) -> void:
	if item_id not in unlocked_items:
		unlocked_items.append(item_id)
		item_unlocked.emit(item_id)

func is_item_unlocked(item_id: String) -> bool:
	return item_id in unlocked_items

func equip_item(slot: int, item_id: String) -> void:
	if slot >= 0 and slot < equipped_items.size():
		equipped_items[slot] = item_id

func get_equipped_item(slot: int) -> String:
	if slot >= 0 and slot < equipped_items.size():
		return equipped_items[slot]
	return ""

func get_all_items() -> Dictionary:
	return items.duplicate()

func get_unlocked_items() -> Array[String]:
	return unlocked_items.duplicate()
