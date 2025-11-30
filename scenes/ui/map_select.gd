extends Control
## MapSelect - Menu de sélection de destination

signal map_selected(map_path: String)
signal closed()

@onready var town_button: Button = $Panel/MarginContainer/VBoxContainer/TownButton
@onready var wilderness_button: Button = $Panel/MarginContainer/VBoxContainer/WildernessButton
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

const MAPS = {
	"town": "res://scenes/world/maps/town.tscn",
	"wilderness": "res://scenes/world/maps/wilderness.tscn"
}

func _ready() -> void:
	town_button.pressed.connect(_on_town_selected)
	wilderness_button.pressed.connect(_on_wilderness_selected)
	close_button.pressed.connect(_on_close_pressed)
	visible = false

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("open_map"):
		close()
	if visible and event.is_action_pressed("pause"):
		close()

func open() -> void:
	visible = true
	GameManager.current_state = GameManager.GameState.INVENTORY

func close() -> void:
	visible = false
	closed.emit()
	GameManager.current_state = GameManager.GameState.PLAYING

func _on_town_selected() -> void:
	map_selected.emit(MAPS.town)
	close()

func _on_wilderness_selected() -> void:
	map_selected.emit(MAPS.wilderness)
	close()

func _on_close_pressed() -> void:
	close()
