extends Control
## DialogueBox - Boîte de dialogue pour les conversations avec les NPCs

signal dialogue_finished()
signal dialogue_advanced()

@onready var panel: PanelContainer = $Panel
@onready var speaker_name: Label = $Panel/MarginContainer/VBoxContainer/SpeakerName
@onready var dialogue_text: RichTextLabel = $Panel/MarginContainer/VBoxContainer/DialogueText
@onready var continue_indicator: Label = $Panel/MarginContainer/VBoxContainer/ContinueIndicator

var dialogue_queue: Array[Dictionary] = []
var current_dialogue_index: int = 0
var is_typing: bool = false
var typing_speed: float = 0.03
var current_text: String = ""
var displayed_characters: int = 0

func _ready() -> void:
	visible = false
	continue_indicator.visible = false

func _process(delta: float) -> void:
	if is_typing:
		# Animation de texte qui apparaît caractère par caractère
		# Simplifié pour l'instant
		pass

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		if is_typing:
			# Afficher tout le texte immédiatement
			_complete_typing()
		else:
			# Passer au dialogue suivant
			_advance_dialogue()

func start_dialogue(dialogues: Array) -> void:
	dialogue_queue.clear()
	for d in dialogues:
		if d is String:
			dialogue_queue.append({"speaker": "", "text": d})
		elif d is Dictionary:
			dialogue_queue.append(d)

	current_dialogue_index = 0
	visible = true
	GameManager.current_state = GameManager.GameState.DIALOGUE
	_show_current_dialogue()

func start_simple_dialogue(speaker: String, lines: Array[String]) -> void:
	dialogue_queue.clear()
	for line in lines:
		dialogue_queue.append({"speaker": speaker, "text": line})

	current_dialogue_index = 0
	visible = true
	GameManager.current_state = GameManager.GameState.DIALOGUE
	_show_current_dialogue()

func _show_current_dialogue() -> void:
	if current_dialogue_index >= dialogue_queue.size():
		_end_dialogue()
		return

	var dialogue = dialogue_queue[current_dialogue_index]
	speaker_name.text = dialogue.get("speaker", "")
	speaker_name.visible = not dialogue.get("speaker", "").is_empty()

	current_text = dialogue.get("text", "")
	dialogue_text.text = current_text
	continue_indicator.visible = true

func _advance_dialogue() -> void:
	current_dialogue_index += 1
	dialogue_advanced.emit()
	_show_current_dialogue()

func _complete_typing() -> void:
	is_typing = false
	dialogue_text.text = current_text
	continue_indicator.visible = true

func _end_dialogue() -> void:
	visible = false
	dialogue_queue.clear()
	current_dialogue_index = 0
	dialogue_finished.emit()
	GameManager.current_state = GameManager.GameState.PLAYING

func close() -> void:
	_end_dialogue()
