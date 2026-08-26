extends HBoxContainer


@export var icons: Dictionary = {
	"none": null,
	"axe": preload("res://weapons/axe/axe_icon.png"),
	"pistol": preload("uid://cmklcupf7m72l"),
}

@onready var player: Player3D = get_tree().get_first_node_in_group("player")

var _last_item := -999

func _ready() -> void:
	refresh()

func _process(_delta: float) -> void:
	if player == null:
		return
	if player.current_item == _last_item:
		return
	_last_item = player.current_item
	refresh()

func refresh() -> void:
	if player == null:
		return
		
	for index in range(mini(9, player.inventory.size())):
		var slot := get_child(index) as Panel
		if slot == null:
			continue
		var item_id: String = player.inventory[index]
		var icon := slot.get_node_or_null("Icon") as TextureRect
		if icon == null:
			continue
		icon.texture = icons.get(item_id, null)
		
		if index == player.current_item:
			slot.modulate = Color(1.3, 1.3, 1.0)
		else:
			slot.modulate = Color.WHITE
