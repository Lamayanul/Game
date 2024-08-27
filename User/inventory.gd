extends PanelContainer

@onready var grid_container = $MarginContainer/GridContainer
@export var itemArray: Array[Item]

func _ready():
	for child in grid_container.get_children():
		if child is Slot:
			child.connect("slot_selected", Callable(self, "_on_slot_selected"))
			
func add_item_resource() -> void:
	for child in grid_container.get_children():
		if child is Slot and child.slotItemResource == null:
			var item : Item = Item.new()
	
			item.texture = load("res://Sprout Lands - Sprites - Basic pack/Objects/Inventory_Slot.png")
			item.quantity = randi_range(1, 20)
			
	
			itemArray.append(item)
			
			#child.set_item(item)
			return

func clear_all_inventory_items() -> void:
	itemArray.clear()
	
	for child in grid_container.get_children():
		if child is Slot:
			child.set_data_empty()
