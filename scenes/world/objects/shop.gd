extends Area2D
class_name Shop
## Shop - Stand de bonus où le joueur peut acheter des améliorations

signal item_purchased(item_id: String)

enum ShopItem { HEALTH, SPEED_BOOST, DAMAGE_BOOST, EXTRA_JUMP }

@export var items_for_sale: Array[ShopItem] = [ShopItem.HEALTH, ShopItem.SPEED_BOOST]

const ITEM_DATA = {
	ShopItem.HEALTH: {"name": "Soin", "cost": 30, "description": "+1 PV"},
	ShopItem.SPEED_BOOST: {"name": "Vitesse", "cost": 50, "description": "Vitesse +20% (niveau)"},
	ShopItem.DAMAGE_BOOST: {"name": "Force", "cost": 75, "description": "Dégâts +1 (niveau)"},
	ShopItem.EXTRA_JUMP: {"name": "Double Saut", "cost": 100, "description": "Active le double saut"}
}

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_label: Label = $InteractionLabel

var player_in_range: bool = false
var player_ref: Node = null
var current_selection: int = 0
var is_shopping: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_setup_visual()
	interaction_label.visible = false

func _setup_visual() -> void:
	# Créer un sprite de shop simple (petit stand)
	var texture = load("res://assets/sprites/environment/shop_stand.svg")
	if texture:
		sprite.texture = texture
	else:
		# Fallback: colored rect
		sprite.modulate = Color(0.8, 0.6, 0.2, 1)

func _input(event: InputEvent) -> void:
	if not player_in_range or not player_ref:
		return

	if event.is_action_pressed("interact"):
		if not is_shopping:
			_open_shop()
		else:
			_purchase_current_item()

	if is_shopping:
		if event.is_action_pressed("move_up"):
			current_selection = max(0, current_selection - 1)
			_update_shop_ui()
		elif event.is_action_pressed("move_down"):
			current_selection = min(items_for_sale.size() - 1, current_selection + 1)
			_update_shop_ui()
		elif event.is_action_pressed("pause") or event.is_action_pressed("move_left"):
			_close_shop()

func _open_shop() -> void:
	is_shopping = true
	current_selection = 0
	GameManager.enter_dialogue()  # Pause le jeu partiellement
	_update_shop_ui()

func _close_shop() -> void:
	is_shopping = false
	GameManager.exit_dialogue()
	interaction_label.text = "[C] Shop"

func _update_shop_ui() -> void:
	var text = "=== SHOP ===\n"
	for i in range(items_for_sale.size()):
		var item = items_for_sale[i]
		var data = ITEM_DATA[item]
		var prefix = "> " if i == current_selection else "  "
		var affordable = GameManager.has_currency(data.cost)
		var color_tag = "" if affordable else "[GRISE]"
		text += "%s%s - %dK %s\n" % [prefix, data.name, data.cost, color_tag]

	text += "\n[C] Acheter | [←] Fermer"
	text += "\nVos K: %d" % GameManager.get_currency()

	interaction_label.text = text

func _purchase_current_item() -> void:
	if current_selection >= items_for_sale.size():
		return

	var item = items_for_sale[current_selection]
	var data = ITEM_DATA[item]

	if not GameManager.spend_currency(data.cost):
		# Pas assez de K
		print("Pas assez de K!")
		return

	# Appliquer l'effet
	match item:
		ShopItem.HEALTH:
			if player_ref and player_ref.has_method("heal"):
				player_ref.heal(1)
				print("Soin acheté!")
		ShopItem.SPEED_BOOST:
			# Boost de vitesse via multiplicateur
			if player_ref:
				if not player_ref.has_meta("speed_multiplier"):
					player_ref.set_meta("speed_multiplier", 1.0)
				var current = player_ref.get_meta("speed_multiplier")
				player_ref.set_meta("speed_multiplier", current * 1.2)
				print("Vitesse augmentée! (x", player_ref.get_meta("speed_multiplier"), ")")
		ShopItem.DAMAGE_BOOST:
			# Augmenter les dégâts via meta
			if player_ref:
				if not player_ref.has_meta("damage_bonus"):
					player_ref.set_meta("damage_bonus", 0)
				var current = player_ref.get_meta("damage_bonus")
				player_ref.set_meta("damage_bonus", current + 1)
				print("Force augmentée! (+", player_ref.get_meta("damage_bonus"), ")")
		ShopItem.EXTRA_JUMP:
			if player_ref:
				player_ref.has_double_jump = true
				print("Double saut débloqué!")

	item_purchased.emit(str(item))
	_update_shop_ui()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = true
		player_ref = body
		interaction_label.visible = true
		interaction_label.text = "[C] Shop"

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		player_ref = null
		interaction_label.visible = false
		if is_shopping:
			_close_shop()
