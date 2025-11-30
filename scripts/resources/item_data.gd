extends Resource
class_name ItemData
## ItemData - Resource représentant un objet du jeu

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.COLLECTIBLE
@export var stackable: bool = true
@export var actions: Array[String] = []

enum ItemType {
	COLLECTIBLE,
	USABLE,
	KEY,
	CONSUMABLE
}

func use(action: String, user: Node, target: Node = null) -> bool:
	match id:
		"fan":
			return _use_fan(action, user, target)
		"slingshot":
			return _use_slingshot(action, user, target)
		"candle":
			return _use_candle(action, user, target)
	return false

func _use_fan(action: String, user: Node, target: Node) -> bool:
	match action:
		"wind":
			# Pousser les objets légers
			print("Utilisation de l'éventail: vent!")
			return true
		"scare_birds":
			# Faire fuir les oiseaux
			print("Utilisation de l'éventail: effrayer les oiseaux!")
			return true
		"throw":
			# Lancer sur une cible
			print("Lancement de l'éventail!")
			return true
	return false

func _use_slingshot(action: String, user: Node, target: Node) -> bool:
	match action:
		"break_ladder":
			# Casser une échelle
			print("Utilisation du lance-pierres: casser l'échelle!")
			return true
		"activate_mechanism":
			# Activer un mécanisme à distance
			print("Utilisation du lance-pierres: activer le mécanisme!")
			return true
		"throw":
			# Tirer sur une cible
			print("Tir avec le lance-pierres!")
			return true
	return false

func _use_candle(action: String, user: Node, target: Node) -> bool:
	match action:
		"light":
			# Éclairer la zone
			print("La bougie éclaire la zone!")
			return true
		"start_fire":
			# Allumer un feu
			print("La bougie allume un feu!")
			return true
		"wear_on_head":
			# Porter sur la tête
			print("Bougie placée sur la tête!")
			return true
	return false
