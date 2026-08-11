extends HBoxContainer


@export var icons: Dictionary = {
	"none": null,
	"axe": preload("res://weapons/axe/axe_icon.png"),
}

@onready var player: Player3D = get_parent().get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refresh()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
