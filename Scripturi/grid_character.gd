extends GridContainer
@onready var slot_container: Slot = $SlotContainer
@onready var slot_container_2: Slot = $SlotContainer2
@onready var slot_container_4: Slot = $SlotContainer4
@onready var slot_container_3: Slot = $SlotContainer3

func _ready():
	slot_container_2.connect("clothes_changed", Callable(self, "_on_clothes_changed"))

func get_player():
	return get_tree().get_first_node_in_group("player")


func _on_clothes_changed(new_clothes_id):
	if new_clothes_id == "25":
		get_player().set_clothes("golden")
	else:
		get_player().set_clothes("")
