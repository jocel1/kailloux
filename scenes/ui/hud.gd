extends Control
## HUD - Interface utilisateur pendant le jeu

@onready var item_slots: HBoxContainer = $MarginContainer/VBoxContainer/ItemSlots
@onready var interaction_hint: Label = $InteractionHint
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var dialogue_text: Label = $DialogueBox/MarginContainer/DialogueText
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HealthContainer/HealthBar
@onready var health_text: Label = $MarginContainer/VBoxContainer/TopBar/HealthContainer/HealthText
@onready var level_label: Label = $MarginContainer/VBoxContainer/TopBar/LevelContainer/LevelLabel
@onready var currency_label: Label = $MarginContainer/VBoxContainer/TopBar/LevelContainer/CurrencyLabel

var dialogue_queue: Array[String] = []

func _ready() -> void:
	dialogue_box.visible = false
	interaction_hint.visible = false

	# Connecter aux signaux
	InventoryManager.inventory_changed.connect(_update_item_slots)
	GameManager.currency_changed.connect(_update_currency)
	GameManager.level_changed.connect(_update_level)
	GameManager.player_died.connect(_on_player_died)

	_update_item_slots()
	_update_currency(GameManager.get_currency())
	_update_level(GameManager.current_level)

func _process(_delta: float) -> void:
	_update_interaction_hint()
	_update_health()

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
		interaction_hint.text = "[C] Interagir"
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

func _update_health() -> void:
	var player = GameManager.get_player()
	if player:
		health_bar.max_value = player.MAX_HEALTH
		health_bar.value = player.current_health
		health_text.text = "%d / %d" % [player.current_health, player.MAX_HEALTH]

		# Changer la couleur selon la vie
		if player.current_health <= 1:
			health_bar.modulate = Color(1, 0.3, 0.3)  # Rouge
		elif player.current_health <= 2:
			health_bar.modulate = Color(1, 0.7, 0.3)  # Orange
		else:
			health_bar.modulate = Color(0.3, 1, 0.3)  # Vert

func _update_currency(amount: int) -> void:
	currency_label.text = "%d K" % amount

func _update_level(level: int) -> void:
	level_label.text = "NIVEAU %d" % level
	# Cacher le dialogue quand on change de niveau
	hide_dialogue()

func _on_player_died() -> void:
	# Afficher un message de mort
	show_dialogue("Tu es mort! Réapparition...")
