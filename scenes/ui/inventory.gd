extends Control
## Inventory - Écran d'inventaire complet

signal closed()
signal item_selected(item_id: String)

@onready var item_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/ItemGrid
@onready var item_description: Label = $Panel/MarginContainer/VBoxContainer/ItemDescription
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var selected_item: String = ""

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	visible = false

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("open_inventory"):
		close()
	if visible and event.is_action_pressed("pause"):
		close()

func open() -> void:
	_refresh_items()
	visible = true
	GameManager.current_state = GameManager.GameState.INVENTORY

func close() -> void:
	visible = false
	closed.emit()
	GameManager.current_state = GameManager.GameState.PLAYING

func _refresh_items() -> void:
	# Clear existing items
	for child in item_grid.get_children():
		child.queue_free()

	# Add items from inventory
	var items = InventoryManager.get_all_items()
	for item_id in items:
		_add_item_slot(item_id, items[item_id])

	# Add unlocked usable items
	for item_id in InventoryManager.get_unlocked_items():
		if not items.has(item_id):
			_add_item_slot(item_id, 0, true)

func _add_item_slot(item_id: String, quantity: int, is_unlocked: bool = false) -> void:
	var slot = Button.new()
	slot.custom_minimum_size = Vector2(64, 64)

	var label_text = item_id.substr(0, 4).to_upper()
	if quantity > 0:
		label_text += "\nx" + str(quantity)
	elif is_unlocked:
		label_text += "\n[U]"

	slot.text = label_text
	slot.pressed.connect(_on_item_slot_pressed.bind(item_id))
	item_grid.add_child(slot)

func _on_item_slot_pressed(item_id: String) -> void:
	selected_item = item_id
	item_selected.emit(item_id)
	_show_item_description(item_id)

func _show_item_description(item_id: String) -> void:
	# TODO: Charger depuis items.json
	item_description.text = "Item: " + item_id

func _on_close_pressed() -> void:
	close()
