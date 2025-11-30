extends Control
## HUD - Interface utilisateur pendant le jeu

@onready var item_slots: HBoxContainer = $MarginContainer/VBoxContainer/ItemSlots
@onready var interaction_hint: Label = $InteractionHint
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var dialogue_text: Label = $DialogueBox/MarginContainer/DialogueText

var dialogue_queue: Array[String] = []

func _ready() -> void:
	dialogue_box.visible = false
	interaction_hint.visible = false

	# Connecter aux signaux de l'inventaire
	InventoryManager.inventory_changed.connect(_update_item_slots)
	_update_item_slots()

func _process(_delta: float) -> void:
	_update_interaction_hint()

func _update_item_slots() -> void:
	var slots = item_slots.get_children()
	for i in range(slots.size()):
		var slot = slots[i]
		var item_id = InventoryManager.get_equipped_item(i)
		if slot.has_node("Label"):
			var label = slot.get_node("Label")
			if item_id.is_empty():
				label.text = str(i + 1)
			else:
				label.text = item_id.substr(0, 3).to_upper()

func _update_interaction_hint() -> void:
	var player = GameManager.get_player()
	if player and player.interactable_objects.size() > 0:
		interaction_hint.text = "[E] Interagir"
		interaction_hint.visible = true
	else:
		interaction_hint.visible = false

func show_dialogue(text: String) -> void:
	dialogue_queue.append(text)
	if not dialogue_box.visible:
		_show_next_dialogue()

func _show_next_dialogue() -> void:
	if dialogue_queue.is_empty():
		dialogue_box.visible = false
		return

	var text = dialogue_queue.pop_front()
	dialogue_text.text = text
	dialogue_box.visible = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and dialogue_box.visible:
		_show_next_dialogue()

func hide_dialogue() -> void:
	dialogue_queue.clear()
	dialogue_box.visible = false
