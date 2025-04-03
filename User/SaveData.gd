extends Resource
class_name SaveData


@export var player_data: Dictionary = {
	"health": 0,
	"position": Vector2.ZERO,
}

@export var title:String
@export var scor: int=0
@export var gaina_position: Vector2 = Vector2.ZERO
@export var enemy_position: Vector2 = Vector2.ZERO
@export var rocks_position: Array=[]
@export var trees_position: Array = []
@export var item_positions: Array = []
@export var item_ids: Array = []
@export var inv_item: Array = []
@export var chest_items: Array = []
